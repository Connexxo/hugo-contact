package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"net/smtp"
	"os"
)

var logger *slog.Logger

func sendEmail(name, email, message string) error {
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USERNAME")
	smtpPass := os.Getenv("SMTP_PASSWORD")
	recipient := os.Getenv("RECIPIENT_EMAIL")

	if smtpHost == "" || smtpPort == "" || smtpUser == "" || smtpPass == "" || recipient == "" {
		return fmt.Errorf("missing required SMTP environment variables")
	}

	body := fmt.Sprintf("From: %s\nTo: %s\nSubject: Contact Form Submission\n\nName: %s\nEmail: %s\nMessage:\n%s",
		smtpUser, recipient, name, email, message)
	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
	return smtp.SendMail(smtpHost+":"+smtpPort, auth, smtpUser, []string{recipient}, []byte(body))
}

func contactHandler(w http.ResponseWriter, r *http.Request) {
	setCORSHeaders(w, r)

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		logger.Warn("Invalid HTTP method", slog.String("method", r.Method))
		return
	}

	_ = r.ParseForm()

	if r.FormValue("_gotcha") != "" || r.FormValue("nickname") != "" {
		logger.Info("Honeypot field triggered — likely a bot", slog.String("ip", r.RemoteAddr))
		w.WriteHeader(http.StatusOK)
		return
	}

	name := r.FormValue("name")
	email := r.FormValue("email")
	message := r.FormValue("message")

	if name == "" || email == "" || message == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		logger.Warn("Missing required fields", slog.String("ip", r.RemoteAddr))
		return
	}

	err := sendEmail(name, email, message)
	if err != nil {
		http.Error(w, "Failed to send message", http.StatusInternalServerError)
		logger.Error("Failed to send email", slog.String("error", err.Error()), slog.String("ip", r.RemoteAddr))
		return
	}

	logger.Info("Email sent successfully", slog.String("name", name), slog.String("email", email), slog.String("ip", r.RemoteAddr))

	if next := r.FormValue("_next"); next != "" {
		http.Redirect(w, r, next, http.StatusSeeOther)
	} else {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("Thanks! Your message was sent."))
	}
}

func setCORSHeaders(w http.ResponseWriter, r *http.Request) {
	origin := r.Header.Get("Origin")
	allowedOrigin := os.Getenv("CORS_ALLOW_ORIGIN")
	if allowedOrigin == "" {
		allowedOrigin = "*"
	}
	if origin != "" {
		w.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.Header().Set("Access-Control-Max-Age", "86400")
	}
}

func main() {
	logger = slog.New(slog.NewJSONHandler(os.Stdout, nil))

	// /f/contact endpoint is the Formspree-compatible POST endpoint
	http.HandleFunc("/f/contact", contactHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	server := &http.Server{
		Addr:    ":" + port,
		Handler: http.DefaultServeMux,
		ErrorLog: slog.NewLogLogger(
			slog.NewJSONHandler(os.Stdout, nil),
			slog.LevelError,
		),
	}

	logger.Info("Starting form handler", slog.String("port", port))
	err := server.ListenAndServe()
	if err != nil {
		logger.Error("Server failed", slog.String("error", err.Error()))
	}
}
