package main

import (
	"encoding/json"
	"fmt"
	"html"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	maxSubjectLength = 200
	maxEmailLength   = 100
	maxMessageLength = 500
	maxLogSizeMB     = 10
	defaultLogDir    = "/var/log/hugo-contact"
)

type SpamLogEntry struct {
	Timestamp   time.Time `json:"timestamp"`
	SenderEmail string    `json:"sender_email"`
	Subject     string    `json:"subject"`
	Message     string    `json:"message"`
	Reason      string    `json:"reason"`
	ClientIP    string    `json:"client_ip"`
}

type SpamLogger struct {
	mu         sync.Mutex
	logDir     string
	maxSizeMB  int
	retentionDays int
}

func NewSpamLogger() *SpamLogger {
	logDir := os.Getenv("SPAM_LOG_DIR")
	if logDir == "" {
		logDir = defaultLogDir
	}

	maxSizeMB := 10
	if envSize := os.Getenv("SPAM_LOG_MAX_SIZE_MB"); envSize != "" {
		if size, err := strconv.Atoi(envSize); err == nil && size > 0 {
			maxSizeMB = size
		}
	}

	retentionDays := 10 // Changed from 30 to 10 as requested
	if envDays := os.Getenv("SPAM_LOG_RETENTION_DAYS"); envDays != "" {
		if days, err := strconv.Atoi(envDays); err == nil && days > 0 {
			retentionDays = days
		}
	}

	return &SpamLogger{
		logDir:        logDir,
		maxSizeMB:     maxSizeMB,
		retentionDays: retentionDays,
	}
}

func (sl *SpamLogger) sanitizeString(input string, maxLength int) string {
	// HTML escape to prevent injection
	sanitized := html.EscapeString(input)
	
	// Remove any control characters
	sanitized = strings.Map(func(r rune) rune {
		if r < 32 && r != '\t' && r != '\n' {
			return -1
		}
		return r
	}, sanitized)
	
	// Truncate to max length
	if len(sanitized) > maxLength {
		sanitized = sanitized[:maxLength]
	}
	
	return strings.TrimSpace(sanitized)
}

func (sl *SpamLogger) LogSpam(email, subject, message, reason, clientIP string) error {
	sl.mu.Lock()
	defer sl.mu.Unlock()

	// Ensure log directory exists
	if err := os.MkdirAll(sl.logDir, 0755); err != nil {
		return fmt.Errorf("failed to create log directory: %w", err)
	}

	// Sanitize inputs
	entry := SpamLogEntry{
		Timestamp:   time.Now(),
		SenderEmail: sl.sanitizeString(email, maxEmailLength),
		Subject:     sl.sanitizeString(subject, maxSubjectLength),
		Message:     sl.sanitizeString(message, maxMessageLength),
		Reason:      sl.sanitizeString(reason, 100),
		ClientIP:    sl.sanitizeString(clientIP, 50),
	}

	// Get current log file path
	logFile := sl.getCurrentLogFile()
	
	// Check if rotation is needed
	if err := sl.rotateIfNeeded(logFile); err != nil {
		return fmt.Errorf("failed to rotate log: %w", err)
	}

	// Open file for appending
	file, err := os.OpenFile(logFile, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}
	defer file.Close()

	// Write JSON entry
	encoder := json.NewEncoder(file)
	if err := encoder.Encode(entry); err != nil {
		return fmt.Errorf("failed to write log entry: %w", err)
	}

	// Clean old logs
	go sl.cleanOldLogs()

	return nil
}

func (sl *SpamLogger) getCurrentLogFile() string {
	date := time.Now().Format("2006-01-02")
	return filepath.Join(sl.logDir, fmt.Sprintf("spam-%s.jsonl", date))
}

func (sl *SpamLogger) rotateIfNeeded(logFile string) error {
	info, err := os.Stat(logFile)
	if os.IsNotExist(err) {
		return nil // File doesn't exist yet
	}
	if err != nil {
		return err
	}

	// Check size
	maxSize := int64(sl.maxSizeMB) * 1024 * 1024
	if info.Size() >= maxSize {
		// Rotate by adding timestamp
		rotatedFile := fmt.Sprintf("%s.%d", logFile, time.Now().Unix())
		return os.Rename(logFile, rotatedFile)
	}

	return nil
}

func (sl *SpamLogger) cleanOldLogs() {
	cutoff := time.Now().AddDate(0, 0, -sl.retentionDays)
	
	files, err := filepath.Glob(filepath.Join(sl.logDir, "spam-*.jsonl*"))
	if err != nil {
		return
	}

	for _, file := range files {
		info, err := os.Stat(file)
		if err != nil {
			continue
		}
		
		if info.ModTime().Before(cutoff) {
			os.Remove(file)
		}
	}
}

func (sl *SpamLogger) GetRecentSpamLogs(hours int) ([]SpamLogEntry, error) {
	sl.mu.Lock()
	defer sl.mu.Unlock()

	cutoff := time.Now().Add(-time.Duration(hours) * time.Hour)
	var entries []SpamLogEntry

	// Get log files from the last N hours
	files, err := filepath.Glob(filepath.Join(sl.logDir, "spam-*.jsonl"))
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		fileEntries, err := sl.readLogFile(file, cutoff)
		if err != nil {
			continue // Skip files with errors
		}
		entries = append(entries, fileEntries...)
	}

	return entries, nil
}

func (sl *SpamLogger) readLogFile(filename string, cutoff time.Time) ([]SpamLogEntry, error) {
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