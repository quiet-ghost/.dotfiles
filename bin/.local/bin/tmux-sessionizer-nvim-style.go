package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var (
	// Clean color palette matching nvim plugin
	primaryColor    = lipgloss.Color("#f38ba8") // pink/red for title and accents
	activeColor     = lipgloss.Color("#a6e3a1") // green for active sessions
	inactiveColor   = lipgloss.Color("#6c7086") // gray for inactive
	textColor       = lipgloss.Color("#cdd6f4") // light text
	borderColor     = lipgloss.Color("#45475a") // subtle border
	backgroundColor = lipgloss.Color("#1e1e2e") // dark background

	// Simple styles matching the screenshot
	titleStyle = lipgloss.NewStyle().
			Foreground(primaryColor).
			Bold(true).
			Align(lipgloss.Center)

	// Consistent sizing - no more size changes
	sessionListStyle = lipgloss.NewStyle().
				Border(lipgloss.RoundedBorder()).
				BorderForeground(borderColor).
				Padding(1, 2).
				Width(50).
				Height(28)

	// Full width style for new session mode (no right panel)
	sessionListStyleFull = lipgloss.NewStyle().
				Border(lipgloss.RoundedBorder()).
				BorderForeground(borderColor).
				Padding(1, 2).
				Width(110).
				Height(28)

	detailPanelStyle = lipgloss.NewStyle().
				Border(lipgloss.RoundedBorder()).
				BorderForeground(borderColor).
				Padding(1, 2).
				Width(60).
				Height(28)
	selectedSessionStyle = lipgloss.NewStyle().
				Foreground(textColor).
				Background(lipgloss.Color("#313244")).
				Bold(true)

	normalSessionStyle = lipgloss.NewStyle().
				Foreground(textColor)

	activeIndicatorStyle = lipgloss.NewStyle().
				Foreground(activeColor).
				Bold(true)

	inactiveIndicatorStyle = lipgloss.NewStyle().
				Foreground(inactiveColor)

	keybindStyle = lipgloss.NewStyle().
			Foreground(inactiveColor)

	detailHeaderStyle = lipgloss.NewStyle().
				Foreground(primaryColor).
				Bold(true)

	detailTextStyle = lipgloss.NewStyle().
			Foreground(textColor)

	windowStyle = lipgloss.NewStyle().
			Foreground(textColor).
			MarginLeft(2)

	pathStyle = lipgloss.NewStyle().
			Foreground(inactiveColor)

	// Style for highlighting matched letters
	highlightStyle = lipgloss.NewStyle().
			Foreground(textColor).
			Bold(true)
)

type AppMode int

const (
	ModeNormal AppMode = iota
	ModeSearch
	ModeNewSession
	ModeRename
)

type ViewMode int

const (
	ViewSessions ViewMode = iota
	ViewProjects
)

type item struct {
	title       string
	desc        string
	path        string
	isSession   bool
	isAttached  bool
	windowCount string
}

type model struct {
	appMode      AppMode
	viewMode     ViewMode
	items        []item
	allItems     []item
	cursor       int
	searchInput  textinput.Model
	choice       string
	action       string
	quitting     bool
	width        int
	height       int
	message      string
	renameTarget string
}

func (m model) Init() tea.Cmd {
	return textinput.Blink
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		switch m.appMode {
		case ModeNormal:
			return m.handleNormalMode(msg)
		case ModeSearch:
			return m.handleSearchMode(msg)
		case ModeNewSession:
			return m.handleNewSessionMode(msg)
		case ModeRename:
			return m.handleRenameMode(msg)
		}
	}

	return m, cmd
}

func (m model) handleNormalMode(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch keypress := msg.String(); keypress {
	case "ctrl+c", "q", "esc":
		m.quitting = true
		return m, tea.Quit

	case "i":
		// Enter search mode (vim-like)
		m.appMode = ModeSearch
		m.searchInput.Focus()
		m.searchInput.SetValue("")
		return m, textinput.Blink

	case "n":
		// Enter new session mode - load projects and show all initially
		m.appMode = ModeNewSession
		m.viewMode = ViewProjects
		m.allItems = getProjectItems() // Load all projects
		m.items = m.allItems           // Show all initially (fzf-like)
		// Start at bottom for new session mode (where best matches will be)
		if len(m.items) > 0 {
			m.cursor = len(m.items) - 1
		} else {
			m.cursor = 0
		}
		m.searchInput.Focus()
		m.searchInput.SetValue("")
		m.searchInput.Placeholder = "Type project name, GitHub URL, or custom session name..."
		return m, textinput.Blink

	case "d":
		// Kill session (only in session view)
		if m.viewMode == ViewSessions && len(m.items) > 0 && m.cursor < len(m.items) {
			selectedItem := m.items[m.cursor]
			if selectedItem.isSession {
				err := killTmuxSession(selectedItem.title)
				if err != nil {
					m.message = fmt.Sprintf("Error killing session: %v", err)
				} else {
					m.message = fmt.Sprintf("Session '%s' killed", selectedItem.title)
					m.refreshItems() // Refresh the list
				}
			}
		}
		return m, nil

	case "r":
		// Rename session (only in session view)
		if m.viewMode == ViewSessions && len(m.items) > 0 && m.cursor < len(m.items) {
			selectedItem := m.items[m.cursor]
			if selectedItem.isSession {
				m.appMode = ModeRename
				m.renameTarget = selectedItem.title
				m.searchInput.Focus()
				m.searchInput.SetValue(selectedItem.title)
				m.searchInput.Placeholder = "Enter new session name..."
				return m, textinput.Blink
			}
		}
		return m, nil

	case "R":
		// Refresh
		m.refreshItems()
		m.message = "Refreshed"
		return m, nil

	case "s":
		// Switch to sessions view
		m.viewMode = ViewSessions
		m.refreshItems()
		return m, nil

	case "p":
		// Switch to projects view
		m.viewMode = ViewProjects
		m.refreshItems()
		return m, nil

	case "enter":
		// Select current item
		if len(m.items) > 0 && m.cursor < len(m.items) {
			selectedItem := m.items[m.cursor]
			m.choice = selectedItem.path
			if selectedItem.isSession {
				m.action = "switch"
			} else {
				m.action = "create"
			}
			return m, tea.Quit
		}

	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}

	case "down", "j":
		if m.cursor < len(m.items)-1 {
			m.cursor++
		}

	case "1", "2", "3", "4", "5", "6", "7", "8", "9":
		// Quick select by number
		num, _ := strconv.Atoi(keypress)
		if num > 0 && num <= len(m.items) {
			selectedItem := m.items[num-1]
			m.choice = selectedItem.path
			if selectedItem.isSession {
				m.action = "switch"
			} else {
				m.action = "create"
			}
			return m, tea.Quit
		}
	}

	return m, nil
}

func (m model) handleSearchMode(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg.String() {
	case "esc", "ctrl+c":
		// Exit search mode
		m.appMode = ModeNormal
		m.searchInput.Blur()
		m.items = m.allItems
		m.cursor = 0
		return m, nil

	case "enter":
		// Select first filtered item
		if len(m.items) > 0 {
			selectedItem := m.items[0]
			m.choice = selectedItem.path
			if selectedItem.isSession {
				m.action = "switch"
			} else {
				m.action = "create"
			}
			return m, tea.Quit
		}
		return m, nil

	case "down", "ctrl+j":
		if m.cursor < len(m.items)-1 {
			m.cursor++
		}
		return m, nil

	case "up", "ctrl+k":
		if m.cursor > 0 {
			m.cursor--
		}
		return m, nil
	}

	// Update search input
	m.searchInput, cmd = m.searchInput.Update(msg)

	// Filter items based on search
	m.filterItems(m.searchInput.Value())

	return m, cmd
}

func (m model) handleNewSessionMode(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg.String() {
	case "esc", "ctrl+c":
		// Exit new session mode
		m.appMode = ModeNormal
		m.searchInput.Blur()
		m.viewMode = ViewSessions
		m.refreshItems()
		return m, nil

	case "enter":
		// Create session with search term or select filtered project
		searchTerm := strings.TrimSpace(m.searchInput.Value())
		if searchTerm != "" {
			// Check if it's a GitHub URL
			if isGitHubURL(searchTerm) {
				m.choice = searchTerm
				m.action = "clone_and_create"
				return m, tea.Quit
			} else if len(m.items) > 0 {
				// Use selected filtered project (cursor position)
				if m.cursor < len(m.items) {
					selectedItem := m.items[m.cursor]
					m.choice = selectedItem.path
					m.action = "create"
				} else {
					// Fallback to first item
					selectedItem := m.items[0]
					m.choice = selectedItem.path
					m.action = "create"
				}
			} else {
				// Create session with search term as name
				m.choice = searchTerm
				m.action = "create_named"
			}
			return m, tea.Quit
		}
		return m, nil

	case "down", "ctrl+j":
		if m.cursor < len(m.items)-1 {
			m.cursor++
		}
		return m, nil

	case "up", "ctrl+k":
		if m.cursor > 0 {
			m.cursor--
		}
		return m, nil
	}

	// Update search input
	m.searchInput, cmd = m.searchInput.Update(msg)

	// Filter items based on search
	m.filterItems(m.searchInput.Value())

	return m, cmd
}

func (m model) handleRenameMode(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg.String() {
	case "esc", "ctrl+c":
		// Exit rename mode
		m.appMode = ModeNormal
		m.searchInput.Blur()
		m.renameTarget = ""
		return m, nil

	case "enter":
		// Rename the session
		newName := strings.TrimSpace(m.searchInput.Value())
		if newName != "" && newName != m.renameTarget {
			err := renameTmuxSession(m.renameTarget, newName)
			if err != nil {
				m.message = fmt.Sprintf("Error renaming session: %v", err)
			} else {
				m.message = fmt.Sprintf("Session renamed to '%s'", newName)
				m.refreshItems() // Refresh to show new name
			}
		}
		m.appMode = ModeNormal
		m.searchInput.Blur()
		m.renameTarget = ""
		return m, nil
	}

	// Update search input
	m.searchInput, cmd = m.searchInput.Update(msg)
	return m, cmd
}

type searchResult struct {
	item  item
	score int
}

func (m *model) filterItems(query string) {
	if query == "" {
		m.items = m.allItems
		m.cursor = 0
		return
	}

	query = strings.ToLower(query)
	var results []searchResult

	for _, item := range m.allItems {
		score := calculateSearchScore(item, query)
		if score > 0 {
			results = append(results, searchResult{item: item, score: score})
		}
	}

	// Sort by score - for new session mode, put best matches at bottom (fzf-like)
	if m.appMode == ModeNewSession {
		// Lower scores first, higher scores (better matches) at bottom
		sort.Slice(results, func(i, j int) bool {
			return results[i].score < results[j].score
		})
	} else {
		// Normal mode: higher scores first
		sort.Slice(results, func(i, j int) bool {
			return results[i].score > results[j].score
		})
	}

	// Extract items
	var filtered []item
	for _, result := range results {
		filtered = append(filtered, result.item)
	}

	m.items = filtered
	// For new session mode, start cursor at bottom (best match)
	if m.appMode == ModeNewSession && len(filtered) > 0 {
		m.cursor = len(filtered) - 1
	} else {
		m.cursor = 0
	}
}

func calculateSearchScore(item item, query string) int {
	title := strings.ToLower(item.title)
	desc := strings.ToLower(item.desc)

	// No match
	if !strings.Contains(title, query) && !strings.Contains(desc, query) {
		return 0
	}

	score := 0

	// Exact title match gets highest priority
	if title == query {
		score += 1000
	}

	// Title starts with query
	if strings.HasPrefix(title, query) {
		score += 500
	}

	// Title contains query
	if strings.Contains(title, query) {
		score += 100
	}

	// Bonus for shorter paths (likely root directories)
	pathDepth := strings.Count(item.desc, "/")
	score += (10 - pathDepth) * 10 // Less depth = higher score

	// Bonus for being in root of dev/personal (likely main projects)
	if strings.Count(item.desc, "/") == 2 { // ~/dev/project or ~/personal/project
		score += 200
	}

	// Description contains query (lower priority)
	if strings.Contains(desc, query) {
		score += 50
	}

	return score
}

func (m *model) refreshItems() {
	if m.viewMode == ViewSessions {
		m.allItems = getSessionItems()
	} else {
		m.allItems = getProjectItems()
	}
	m.items = m.allItems
	m.cursor = 0
}

func (m model) View() string {
	if m.choice != "" {
		return ""
	}
	if m.quitting {
		return ""
	}

	// Title matching the screenshot
	var title string
	switch m.appMode {
	case ModeSearch:
		title = titleStyle.Render(" Search Sessions")
	case ModeNewSession:
		title = titleStyle.Render("+ New Session")
	case ModeRename:
		title = titleStyle.Render(" Rename Session")
	default:
		title = titleStyle.Render(" Tmux Session Manager")
	}

	// Build session/project list based on mode
	var itemLines []string
	itemCount := 0

	// Show search input if in search/new/rename mode - make it subtle
	var searchLine string
	if m.appMode == ModeSearch {
		searchLine = keybindStyle.Render(" ") + m.searchInput.View()
	} else if m.appMode == ModeNewSession {
		searchLine = keybindStyle.Render("+ ") + m.searchInput.View()
	} else if m.appMode == ModeRename {
		searchLine = keybindStyle.Render(" ") + m.searchInput.View()
	}

	// Limit items shown when searching to make list shorter (fzf-like)
	maxItems := len(m.items)
	if m.appMode == ModeSearch || m.appMode == ModeNewSession {
		maxItems = 15 // Show max 15 items when searching (more than before)
	}

	displayedItems := m.items
	displayStart := 0

	if len(displayedItems) > maxItems {
		// Show items around cursor position
		start := m.cursor - maxItems/2
		if start < 0 {
			start = 0
		}
		end := start + maxItems
		if end > len(m.items) {
			end = len(m.items)
			start = end - maxItems
			if start < 0 {
				start = 0
			}
		}
		displayedItems = m.items[start:end]
		displayStart = start
	}

	for i, item := range displayedItems {
		actualIndex := displayStart + i
		itemCount++

		var itemLine string
		if item.isSession {
			// Status indicator: ● for active, ○ for inactive
			var indicator string
			if item.isAttached {
				indicator = activeIndicatorStyle.Render("●")
			} else {
				indicator = inactiveIndicatorStyle.Render("○")
			}
			// Session line format: "1 ○ session-name (window_count)"
			itemLine = fmt.Sprintf("%d %s %s (%s)", actualIndex+1, indicator, item.title, item.windowCount)
		} else {
			// Project line format for new session mode: show full path with highlighting
			if m.appMode == ModeNewSession {
				// Show full path with highlighted matches
				fullPath := item.desc
				if fullPath == "" {
					fullPath = item.path
				}
				// Convert home path to ~
				if strings.HasPrefix(fullPath, os.Getenv("HOME")) {
					fullPath = strings.Replace(fullPath, os.Getenv("HOME"), "~", 1)
				}

				// Highlight matched letters
				highlightedPath := highlightMatches(fullPath, m.searchInput.Value())
				itemLine = fmt.Sprintf("%d %s", actualIndex+1, highlightedPath)
			} else {
				// Normal project line format: "1 project-name"
				itemLine = fmt.Sprintf("%d %s", actualIndex+1, item.title)
				if item.desc != "" {
					itemLine += fmt.Sprintf(" %s", pathStyle.Render(item.desc))
				}
			}
		}

		// Highlight selected item
		if actualIndex == m.cursor {
			itemLine = selectedSessionStyle.Render("▶ " + itemLine)
		} else {
			itemLine = normalSessionStyle.Render("  " + itemLine)
		}

		itemLines = append(itemLines, itemLine)
	}
	// Add fzf-like status line showing results count
	var statusLine string
	if m.appMode == ModeSearch || m.appMode == ModeNewSession {
		totalItems := len(m.items)
		if totalItems > maxItems {
			statusLine = keybindStyle.Render(fmt.Sprintf("  %d/%d", len(displayedItems), totalItems))
		} else if totalItems > 0 {
			statusLine = keybindStyle.Render(fmt.Sprintf("  %d", totalItems))
		}
	}

	// Handle no items case - keep it minimal to reduce jarring
	if itemCount == 0 {
		if m.appMode == ModeNewSession {
			if m.searchInput.Value() != "" {
				// Check if it's a GitHub URL
				if isGitHubURL(m.searchInput.Value()) {
					repoName := extractRepoName(m.searchInput.Value())
					if repoName != "" {
						itemLines = append(itemLines, selectedSessionStyle.Render(fmt.Sprintf("▶ Clone & create session: %s", repoName)))
					} else {
						itemLines = append(itemLines, selectedSessionStyle.Render("▶ Clone repository"))
					}
				} else {
					// Show what will be created when typing
					itemLines = append(itemLines, selectedSessionStyle.Render(fmt.Sprintf("▶ Create session: %s", m.searchInput.Value())))
				}
			} else {
				itemLines = append(itemLines, inactiveIndicatorStyle.Render("No projects found"))
			}
		} else if m.appMode == ModeSearch {
			if m.searchInput.Value() != "" {
				itemLines = append(itemLines, inactiveIndicatorStyle.Render("No matches found"))
			} else {
				itemLines = append(itemLines, inactiveIndicatorStyle.Render("Start typing to search..."))
			}
		} else {
			itemLines = append(itemLines, inactiveIndicatorStyle.Render("No tmux sessions found"))
			itemLines = append(itemLines, keybindStyle.Render("Press 'n' to create a new session"))
		}
	}

	// Keybind help based on mode
	var keybinds []string
	switch m.appMode {
	case ModeSearch, ModeNewSession, ModeRename:
		keybinds = []string{
			keybindStyle.Render("⏎ Enter: select"),
			keybindStyle.Render("↑/↓: navigate"),
			keybindStyle.Render("Esc: cancel"),
		}
	default:
		keybinds = []string{
			keybindStyle.Render("⏎ Enter/1-9: switch"),
			keybindStyle.Render("🗑 d: kill"),
			keybindStyle.Render(" r: rename"),
			keybindStyle.Render("+ n: new"),
			keybindStyle.Render(" i: search"),
			keybindStyle.Render("↻ R: refresh"),
			keybindStyle.Render("× q: quit"),
		}
	}

	// Build left panel content - search goes at bottom, status line after items
	leftContent := []string{title, ""}
	leftContent = append(leftContent, itemLines...)
	if statusLine != "" {
		leftContent = append(leftContent, statusLine)
	}
	leftContent = append(leftContent, "")
	leftContent = append(leftContent, keybinds...)
	if searchLine != "" {
		leftContent = append(leftContent, "", searchLine)
	}

	// Use full width for new session mode (no right panel)
	var leftPanel string
	if m.appMode == ModeNewSession {
		leftPanel = sessionListStyleFull.Render(strings.Join(leftContent, "\n"))
	} else {
		leftPanel = sessionListStyle.Render(strings.Join(leftContent, "\n"))
	}

	// Build right panel (session details) - no right panel for new session mode
	var content string
	if m.appMode == ModeNewSession {
		// No right panel for new session mode - just the full width left panel
		content = leftPanel
	} else {
		// Normal two-panel layout for other modes
		var rightPanel string
		if m.appMode == ModeNormal && len(m.items) > 0 && m.cursor < len(m.items) && m.items[m.cursor].isSession {
			selectedSession := m.items[m.cursor]
			rightPanel = buildSessionDetails(selectedSession.title)
		} else if m.appMode == ModeRename {
			rightPanel = detailPanelStyle.Render("Renaming session...\n\nEnter new name for session")
		} else if m.appMode == ModeSearch {
			rightPanel = detailPanelStyle.Render("Searching sessions...\n\nType to filter by name\n(showing max 15 results)")
		} else {
			rightPanel = detailPanelStyle.Render("No session selected")
		}

		// Combine panels
		content = lipgloss.JoinHorizontal(lipgloss.Top, leftPanel, rightPanel)
	}

	// Center the content on screen
	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, content)
}

// isGitHubURL checks if the input is a GitHub URL (https or ssh)
func isGitHubURL(input string) bool {
	input = strings.TrimSpace(input)
	return strings.HasPrefix(input, "https://github.com/") ||
		strings.HasPrefix(input, "git@github.com:")
}

// extractRepoName extracts repository name from GitHub URL
func extractRepoName(url string) string {
	url = strings.TrimSpace(url)

	if strings.HasPrefix(url, "https://github.com/") {
		// Remove https://github.com/ prefix
		path := strings.TrimPrefix(url, "https://github.com/")
		// Remove .git suffix if present
		path = strings.TrimSuffix(path, ".git")
		// Get just the repo name (last part after /)
		parts := strings.Split(path, "/")
		if len(parts) >= 2 {
			return parts[1]
		}
	} else if strings.HasPrefix(url, "git@github.com:") {
		// Remove git@github.com: prefix
		path := strings.TrimPrefix(url, "git@github.com:")
		// Remove .git suffix if present
		path = strings.TrimSuffix(path, ".git")
		// Get just the repo name (last part after /)
		parts := strings.Split(path, "/")
		if len(parts) >= 2 {
			return parts[1]
		}
	}

	return ""
}

// cloneGitHubRepo clones a GitHub repository to ~/repos/
func cloneGitHubRepo(url string) (string, error) {
	repoName := extractRepoName(url)
	if repoName == "" {
		return "", fmt.Errorf("could not extract repository name from URL")
	}

	// Create ~/dev/repos directory if it doesn't exist
	reposDir := filepath.Join(os.Getenv("HOME"), "dev", "repos")
	if err := os.MkdirAll(reposDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create repos directory: %v", err)
	}

	// Target directory for the clone
	targetDir := filepath.Join(reposDir, repoName)

	// Check if directory already exists
	if _, err := os.Stat(targetDir); err == nil {
		return targetDir, nil // Directory already exists, just return it
	}

	// Clone the repository
	cmd := exec.Command("git", "clone", url, targetDir)
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to clone repository: %v", err)
	}

	return targetDir, nil
}

func buildSessionDetails(sessionName string) string {
	// Session header
	header := detailHeaderStyle.Render(" " + sessionName)

	// Get session info
	statusCmd := exec.Command("tmux", "list-sessions", "-F", "#{session_name}:#{session_attached}:#{session_windows}", "-f", "#{==:#{session_name},"+sessionName+"}")
	statusOutput, err := statusCmd.Output()

	var status, windowCount string
	if err == nil && len(statusOutput) > 0 {
		parts := strings.Split(strings.TrimSpace(string(statusOutput)), ":")
		if len(parts) >= 3 {
			if parts[1] == "1" {
				status = activeIndicatorStyle.Render("⚡ Active")
			} else {
				status = inactiveIndicatorStyle.Render("○ Inactive")
			}
			windowCount = parts[2]
		}
	}

	// Status and window count
	statusLine := fmt.Sprintf("Status: %s", status)
	windowsLine := fmt.Sprintf("Windows: %s", windowCount)

	// Get window details
	windowsCmd := exec.Command("tmux", "list-windows", "-t", sessionName, "-F", "#{window_index}: #{window_name}")
	windowsOutput, err := windowsCmd.Output()

	var windowDetails []string
	windowDetails = append(windowDetails, detailHeaderStyle.Render("⊞ Windows:"))
	if err == nil && len(windowsOutput) > 0 {
		windows := strings.Split(strings.TrimSpace(string(windowsOutput)), "\n")
		for _, window := range windows {
			if window != "" {
				// Get window details including current directory
				parts := strings.SplitN(window, ": ", 2)
				if len(parts) == 2 {
					windowNum := parts[0]
					windowName := parts[1]

					// Get current directory for this window
					dirCmd := exec.Command("tmux", "display-message", "-t", sessionName+":"+windowNum, "-p", "#{pane_current_path}")
					dirOutput, dirErr := dirCmd.Output()

					windowLine := fmt.Sprintf("%s: %s", windowNum, windowName)
					windowDetails = append(windowDetails, windowStyle.Render(windowLine))

					if dirErr == nil {
						currentDir := strings.TrimSpace(string(dirOutput))
						// Convert home path to ~
						if strings.HasPrefix(currentDir, os.Getenv("HOME")) {
							currentDir = strings.Replace(currentDir, os.Getenv("HOME"), "~", 1)
						}
						windowDetails = append(windowDetails, windowStyle.Render("    \uea83 "+pathStyle.Render(currentDir)))
					}
				}
			}
		}
	} else {
		windowDetails = append(windowDetails, windowStyle.Render("No windows found"))
	}

	// Combine all details
	content := []string{
		header,
		"",
		detailTextStyle.Render(statusLine),
		detailTextStyle.Render(windowsLine),
		"",
	}
	content = append(content, windowDetails...)

	return detailPanelStyle.Render(strings.Join(content, "\n"))
}

func getSessionItems() []item {
	var items []item

	// Get tmux sessions
	cmd := exec.Command("tmux", "list-sessions", "-F", "#{session_name}:#{session_attached}:#{session_windows}")
	output, err := cmd.Output()
	if err != nil {
		// No sessions found
		return items
	}

	sessions := strings.Split(strings.TrimSpace(string(output)), "\n")

	for _, session := range sessions {
		if session == "" {
			continue
		}

		parts := strings.Split(session, ":")
		if len(parts) < 3 {
			continue
		}

		name := parts[0]
		attached := parts[1] == "1"
		windows := parts[2]

		items = append(items, item{
			title:       name,
			path:        name, // For sessions, path is the session name
			isSession:   true,
			isAttached:  attached,
			windowCount: windows,
		})
	}

	// Sort by name
	sort.Slice(items, func(i, j int) bool {
		return items[i].title < items[j].title
	})

	return items
}

func getProjectItems() []item {
	var items []item

	// Search paths matching your original script
	searchPaths := []string{
		filepath.Join(os.Getenv("HOME"), "dev"),
		filepath.Join(os.Getenv("HOME"), "personal"),
	}

	for _, searchPath := range searchPaths {
		err := filepath.Walk(searchPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil // Skip errors, continue walking
			}

			if !info.IsDir() {
				return nil
			}

			// Calculate depth relative to search path
			relPath, err := filepath.Rel(searchPath, path)
			if err != nil {
				return nil
			}

			depth := strings.Count(relPath, string(filepath.Separator))
			if relPath == "." {
				depth = 0
			}

			// Only include direct subdirectories of ~/dev and ~/personal (depth 1)
			// Skip hidden directories and node_modules
			if depth == 1 &&
				!strings.HasPrefix(filepath.Base(path), ".") &&
				!strings.Contains(path, "node_modules") {
				name := filepath.Base(path)
				desc := strings.Replace(path, os.Getenv("HOME"), "~", 1)

				items = append(items, item{
					title:     name,
					desc:      desc,
					path:      path,
					isSession: false,
				})
			}

			return nil
		})
		if err != nil {
			continue // Skip this search path if there's an error
		}
	}

	// Sort by name for consistent ordering
	sort.Slice(items, func(i, j int) bool {
		return items[i].title < items[j].title
	})

	return items
}

func createTmuxSession(selectedPath string) error {
	if selectedPath == "" {
		return nil
	}

	// Convert path to session name (same logic as original script)
	selectedName := strings.ReplaceAll(filepath.Base(selectedPath), ".", "_")

	// Check if tmux is running
	tmuxRunning := exec.Command("pgrep", "tmux")
	tmuxRunning.Run()
	tmuxIsRunning := tmuxRunning.ProcessState.Success()

	// Check if we're inside tmux
	_, insideTmux := os.LookupEnv("TMUX")

	// If not in tmux and tmux isn't running, create new session and attach
	if !insideTmux && !tmuxIsRunning {
		// Create session with shell
		cmd := exec.Command("tmux", "new-session", "-s", selectedName, "-c", selectedPath)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		// Start nvim in the background and then attach
		go func() {
			// Small delay to ensure session is created
			time.Sleep(100 * time.Millisecond)
			// Send nvim command to the session
			exec.Command("tmux", "send-keys", "-t", selectedName, "nvim -c \"lua if pcall(require, 'telescope') then vim.cmd('Telescope find_files') end\"", "Enter").Run()
		}()

		return cmd.Run()
	}

	// Check if session already exists
	checkSession := exec.Command("tmux", "has-session", "-t="+selectedName)
	err := checkSession.Run()
	// If session doesn't exist, create it with shell and send nvim command
	if err != nil {
		createCmd := exec.Command("tmux", "new-session", "-d", "-s", selectedName, "-c", selectedPath)
		if err := createCmd.Run(); err != nil {
			return fmt.Errorf("failed to create session: %v", err)
		}

		// Send nvim command to the new session
		nvimCmd := exec.Command("tmux", "send-keys", "-t", selectedName, "nvim -c \"lua if pcall(require, 'telescope') then vim.cmd('Telescope find_files') end\"", "Enter")
		nvimCmd.Run()
	}

	// Switch to the session
	switchCmd := exec.Command("tmux", "switch-client", "-t", selectedName)
	return switchCmd.Run()
}

func createNamedTmuxSession(sessionName string) error {
	if sessionName == "" {
		return nil
	}

	// Clean session name
	sessionName = strings.ReplaceAll(sessionName, ".", "_")
	sessionName = strings.ReplaceAll(sessionName, " ", "_")

	// Check if tmux is running
	tmuxRunning := exec.Command("pgrep", "tmux")
	tmuxRunning.Run()
	tmuxIsRunning := tmuxRunning.ProcessState.Success()

	// Check if we're inside tmux
	_, insideTmux := os.LookupEnv("TMUX")

	// If not in tmux and tmux isn't running, create new session and attach
	if !insideTmux && !tmuxIsRunning {
		// Create session with shell
		cmd := exec.Command("tmux", "new-session", "-s", sessionName)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		// Start nvim in the background and then attach
		go func() {
			// Small delay to ensure session is created
			time.Sleep(100 * time.Millisecond)
			// Send nvim command to the session
			exec.Command("tmux", "send-keys", "-t", sessionName, "nvim -c \"lua if pcall(require, 'telescope') then vim.cmd('Telescope find_files') end\"", "Enter").Run()
		}()

		return cmd.Run()
	}

	// Check if session already exists
	checkSession := exec.Command("tmux", "has-session", "-t="+sessionName)
	err := checkSession.Run()
	// If session doesn't exist, create it
	if err != nil {
		createCmd := exec.Command("tmux", "new-session", "-d", "-s", sessionName)
		if err := createCmd.Run(); err != nil {
			return fmt.Errorf("failed to create session: %v", err)
		}

		// Send nvim command to the new session
		nvimCmd := exec.Command("tmux", "send-keys", "-t", sessionName, "nvim -c \"lua if pcall(require, 'telescope') then vim.cmd('Telescope find_files') end\"", "Enter")
		nvimCmd.Run()
	}

	// Switch to the session
	switchCmd := exec.Command("tmux", "switch-client", "-t", sessionName)
	return switchCmd.Run()
}

func switchTmuxSession(sessionName string) error {
	if sessionName == "" {
		return nil
	}

	// Switch to the session
	switchCmd := exec.Command("tmux", "switch-client", "-t", sessionName)
	return switchCmd.Run()
}

func killTmuxSession(sessionName string) error {
	if sessionName == "" {
		return nil
	}

	// Kill the session
	killCmd := exec.Command("tmux", "kill-session", "-t", sessionName)
	return killCmd.Run()
}

func renameTmuxSession(oldName, newName string) error {
	if oldName == "" || newName == "" {
		return fmt.Errorf("session names cannot be empty")
	}

	// Clean new session name
	newName = strings.ReplaceAll(newName, ".", "_")
	newName = strings.ReplaceAll(newName, " ", "_")

	// Rename the session
	renameCmd := exec.Command("tmux", "rename-session", "-t", oldName, newName)
	return renameCmd.Run()
}

// highlightMatches highlights matched letters in the text
func highlightMatches(text, query string) string {
	if query == "" {
		return pathStyle.Render(text)
	}

	query = strings.ToLower(query)
	textLower := strings.ToLower(text)

	var result strings.Builder
	i := 0

	for i < len(text) {
		if i < len(textLower) && strings.HasPrefix(textLower[i:], query) {
			// Found a match - highlight it
			matchedPart := text[i : i+len(query)]
			result.WriteString(highlightStyle.Render(matchedPart))
			i += len(query)
		} else {
			// No match - use normal style
			result.WriteString(pathStyle.Render(string(text[i])))
			i++
		}
	}

	return result.String()
}

func main() {
	// Initialize search input
	ti := textinput.New()
	ti.Placeholder = "Type to search..."
	ti.CharLimit = 50
	ti.Width = 40

	// Create model
	m := model{
		appMode:     ModeNormal,
		viewMode:    ViewSessions,
		searchInput: ti,
	}

	// Start with sessions if they exist, otherwise projects
	sessionItems := getSessionItems()
	if len(sessionItems) > 0 {
		m.allItems = sessionItems
		m.items = sessionItems
	} else {
		m.viewMode = ViewProjects
		m.allItems = getProjectItems()
		m.items = m.allItems
	}

	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		fmt.Printf("Error: %v", err)
		os.Exit(1)
	}

	// Handle the selection
	if m, ok := finalModel.(model); ok && m.choice != "" {
		switch m.action {
		case "create":
			err := createTmuxSession(m.choice)
			if err != nil {
				fmt.Printf("Error creating tmux session: %v\n", err)
				os.Exit(1)
			}
		case "create_named":
			err := createNamedTmuxSession(m.choice)
			if err != nil {
				fmt.Printf("Error creating tmux session: %v\n", err)
				os.Exit(1)
			}
		case "clone_and_create":
			// Clone GitHub repo and create session
			fmt.Printf("Cloning repository: %s\n", m.choice)
			clonedPath, err := cloneGitHubRepo(m.choice)
			if err != nil {
				fmt.Printf("Error cloning repository: %v\n", err)
				os.Exit(1)
			}
			fmt.Printf("Repository cloned to: %s\n", clonedPath)

			// Create tmux session in the cloned directory
			err = createTmuxSession(clonedPath)
			if err != nil {
				fmt.Printf("Error creating tmux session: %v\n", err)
				os.Exit(1)
			}
		case "switch":
			err := switchTmuxSession(m.choice)
			if err != nil {
				fmt.Printf("Error switching to tmux session: %v\n", err)
				os.Exit(1)
			}
		}
	}
}
