package main

import (
	"encoding/json"
	"fmt"
	"html"
	"io"
	"log"
	"net/smtp"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

type SpamLogEntry struct {
	Timestamp   time.Time `json:"timestamp"`
	SenderEmail string    `json:"sender_email"`
	Subject     string    `json:"subject"`
	Message     string    `json:"message"`
	Reason      string    `json:"reason"`
	ClientIP    string    `json:"client_ip"`
}

func main() {
	// Check if spam reporting is enabled
	if os.Getenv("SPAM_REPORT_ENABLED") != "true" {
		log.Println("Spam reporting is disabled (SPAM_REPORT_ENABLED != true)")
		os.Exit(0)
	}

	// Get log directory
	logDir := os.Getenv("SPAM_LOG_DIR")
	if logDir == "" {
		logDir = "/var/log/hugo-contact"
	}

	// Get entries from last 24 hours
	entries, err := getRecentSpamLogs(logDir, 24)
	if err != nil {
		log.Fatalf("Failed to read spam logs: %v", err)
	}

	// If no spam detected, exit successfully
	if len(entries) == 0 {
		log.Println("No spam detected in the last 24 hours")
		os.Exit(0)
	}

	// Generate and send report
	if err := sendSpamReport(entries); err != nil {
		log.Fatalf("Failed to send spam report: %v", err)
	}

	log.Printf("Spam report sent successfully with %d entries", len(entries))
}

func getRecentSpamLogs(logDir string, hours int) ([]SpamLogEntry, error) {
	cutoff := time.Now().Add(-time.Duration(hours) * time.Hour)
	var entries []SpamLogEntry

	// Get log files
	files, err := filepath.Glob(filepath.Join(logDir, "spam-*.jsonl"))
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		fileEntries, err := readLogFile(file, cutoff)
		if err != nil {
			log.Printf("Warning: failed to read %s: %v", file, err)
			continue
		}
		entries = append(entries, fileEntries...)
	}

	// Sort by timestamp (most recent first)
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Timestamp.After(entries[j].Timestamp)
	})

	return entries, nil
}

func readLogFile(filename string, cutoff time.Time) ([]SpamLogEntry, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var entries []SpamLogEntry
	decoder := json.NewDecoder(file)

	for {
		var entry SpamLogEntry
		if err := decoder.Decode(&entry); err != nil {
			if err == io.EOF {
				break
			}
			continue // Skip malformed entries
		}
		
		if entry.Timestamp.After(cutoff) {
			entries = append(entries, entry)
		}
	}

	return entries, nil
}

func sendSpamReport(entries []SpamLogEntry) error {
	// Get SMTP configuration
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USERNAME")
	smtpPass := os.Getenv("SMTP_PASSWORD")
	senderEmail := os.Getenv("SENDER_EMAIL")
	
	// Get recipient (use SPAM_REPORT_RECIPIENT or fall back to RECIPIENT_EMAIL)
	recipient := os.Getenv("SPAM_REPORT_RECIPIENT")
	if recipient == "" {
		recipient = os.Getenv("RECIPIENT_EMAIL")
	}

	if smtpHost == "" || smtpPort == "" || smtpUser == "" || smtpPass == "" || senderEmail == "" || recipient == "" {
		return fmt.Errorf("missing required SMTP environment variables")
	}

	// Generate HTML email body
	body := generateHTMLReport(entries)
	
	// Create email
	subject := fmt.Sprintf("Daily Spam Report - %d entries blocked", len(entries))
	date := time.Now().Format(time.RFC1123Z)
	
	// Construct email with proper headers
	message := fmt.Sprintf("From: %s\r\n", senderEmail)
	message += fmt.Sprintf("To: %s\r\n", recipient)
	message += fmt.Sprintf("Subject: %s\r\n", subject)
	message += fmt.Sprintf("Date: %s\r\n", date)
	message += "MIME-Version: 1.0\r\n"
	message += "Content-Type: text/html; charset=utf-8\r\n"
	message += "\r\n"
	message += body

	// Send email
	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
	return smtp.SendMail(smtpHost+":"+smtpPort, auth, senderEmail, []string{recipient}, []byte(message))
}

func generateHTMLReport(entries []SpamLogEntry) string {
	var html strings.Builder
	
	html.WriteString(`<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Spam Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; font-weight: bold; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .message-cell { max-width: 300px; word-wrap: break-word; font-size: 0.9em; }
        .truncated { color: #666; font-style: italic; }
        .summary { margin: 20px 0; padding: 15px; background-color: #e8f4f8; border-radius: 5px; }
        .footer { margin-top: 30px; color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>Daily Spam Report</h1>
    <div class="summary">
        <p><strong>Report Date:</strong> ` + time.Now().Format("January 2, 2006") + `</p>
        <p><strong>Total Spam Blocked:</strong> ` + strconv.Itoa(len(entries)) + ` entries</p>
        <p><strong>Reporting Period:</strong> Last 24 hours</p>
    </div>
    
    <table>
        <thead>
            <tr>
                <th>Time</th>
                <th>Sender Email</th>
                <th>Subject</th>
                <th>Message</th>
                <th>Reason</th>
                <th>IP Address</th>
            </tr>
        </thead>
        <tbody>`)

	for _, entry := range entries {
		html.WriteString("<tr>")
		html.WriteString("<td>" + entry.Timestamp.Format("Jan 2 15:04:05") + "</td>")
		html.WriteString("<td>" + escapeHTML(entry.SenderEmail) + "</td>")
		html.WriteString("<td>" + escapeHTML(entry.Subject) + "</td>")
		html.WriteString("<td class=\"message-cell\">" + formatMessage(entry.Message) + "</td>")
		html.WriteString("<td>" + escapeHTML(entry.Reason) + "</td>")
		html.WriteString("<td>" + escapeHTML(entry.ClientIP) + "</td>")
		html.WriteString("</tr>")
	}
	
	html.WriteString(`
        </tbody>
    </table>
    
    <div class="footer">
        <p>This is an automated report from the Hugo Contact Form spam protection system.</p>
        <p>All data has been sanitized to prevent injection attacks.</p>
    </div>
</body>
</html>`)

	return html.String()
}

func escapeHTML(s string) string {
	if s == "" {
		return "(empty)"
	}
	return html.EscapeString(s)
}

func formatMessage(message string) string {
	if message == "" {
		return "<span class=\"truncated\">(empty)</span>"
	}
	
	// Escape HTML first
	escaped := html.EscapeString(message)
	
	// Truncate if too long and add indication
	if len(escaped) > 200 {
		truncated := escaped[:200]
		// Find the last space to avoid cutting words
		if lastSpace := strings.LastIndex(truncated, " "); lastSpace > 150 {
			truncated = truncated[:lastSpace]
		}
		return truncated + "<span class=\"truncated\">... (truncated)</span>"
	}
	
	// Replace newlines with <br> for better display
	escaped = strings.ReplaceAll(escaped, "\n", "<br>")
	escaped = strings.ReplaceAll(escaped, "\r", "")
	
	return escaped
}