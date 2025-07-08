package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var (
	// Color palette matching your nvim plugin
	activeColor   = lipgloss.Color("10") // bright green
	inactiveColor = lipgloss.Color("8")  // gray
	accentColor   = lipgloss.Color("12") // bright blue
	warningColor  = lipgloss.Color("11") // bright yellow
	errorColor    = lipgloss.Color("9")  // bright red

	// Styles
	titleStyle = lipgloss.NewStyle().
			Foreground(accentColor).
			Bold(true).
			Padding(0, 1).
			MarginBottom(1).
			Align(lipgloss.Center)

	helpStyle = lipgloss.NewStyle().
			Foreground(inactiveColor).
			Padding(1, 0).
			Align(lipgloss.Center)

	selectedStyle = lipgloss.NewStyle().
			Foreground(activeColor).
			Bold(true)

	normalStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("15"))

	pathStyle = lipgloss.NewStyle().
			Foreground(inactiveColor).
			Italic(true)

	sessionActiveStyle = lipgloss.NewStyle().
				Foreground(activeColor).
				Bold(true)

	sessionInactiveStyle = lipgloss.NewStyle().
				Foreground(inactiveColor)

	modeStyle = lipgloss.NewStyle().
			Foreground(warningColor).
			Bold(true).
			Align(lipgloss.Center)
)

type Mode int

const (
	ModeProjects Mode = iota
	ModeSessions
)

type item struct {
	title       string
	desc        string
	path        string
	isSession   bool
	isAttached  bool
	windowCount string
}

func (i item) FilterValue() string { return i.title }

type itemDelegate struct{}

func (d itemDelegate) Height() int                             { return 1 }
func (d itemDelegate) Spacing() int                            { return 0 }
func (d itemDelegate) Update(_ tea.Msg, _ *list.Model) tea.Cmd { return nil }
func (d itemDelegate) Render(w io.Writer, m list.Model, index int, listItem list.Item) {
	i, ok := listItem.(item)
	if !ok {
		return
	}

	var str string
	var style lipgloss.Style

	if i.isSession {
		// Session display
		var indicator string
		if i.isAttached {
			indicator = "●"
			style = sessionActiveStyle
		} else {
			indicator = "○"
			style = sessionInactiveStyle
		}
		str = fmt.Sprintf("%s %s (%s windows)", indicator, i.title, i.windowCount)
	} else {
		// Project display
		str = fmt.Sprintf("%s", i.title)
		if i.desc != "" {
			str += fmt.Sprintf(" %s", pathStyle.Render(i.desc))
		}
		style = normalStyle
	}

	fn := style.Render
	if index == m.Index() {
		fn = selectedStyle.Render
		str = "▶ " + str
	} else {
		str = "  " + str
	}

	fmt.Fprint(w, fn(str))
}

type model struct {
	list     list.Model
	choice   string
	action   string
	quitting bool
	mode     Mode
	width    int
	height   int
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.list.SetWidth(msg.Width)
		m.list.SetHeight(msg.Height - 6) // Account for title and help
		return m, nil

	case tea.KeyMsg:
		switch keypress := msg.String(); keypress {
		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit

		case "t":
			// Toggle between modes
			if m.mode == ModeProjects {
				m.mode = ModeSessions
				m.list.SetItems(getSessionItems())
			} else {
				m.mode = ModeProjects
				m.list.SetItems(getProjectItems())
			}
			return m, nil

		case "enter":
			i, ok := m.list.SelectedItem().(item)
			if ok {
				m.choice = i.path
				if i.isSession {
					m.action = "switch"
				} else {
					m.action = "create"
				}
			}
			return m, tea.Quit

		case "ctrl+d":
			// Kill session (only in session mode)
			if m.mode == ModeSessions {
				i, ok := m.list.SelectedItem().(item)
				if ok && i.isSession {
					m.choice = i.title
					m.action = "kill"
					return m, tea.Quit
				}
			}

		case "ctrl+r":
			// Refresh lists
			if m.mode == ModeSessions {
				m.list.SetItems(getSessionItems())
			} else {
				m.list.SetItems(getProjectItems())
			}
			return m, nil
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m model) View() string {
	if m.choice != "" {
		return ""
	}
	if m.quitting {
		return ""
	}

	var title string
	var help string
	var modeIndicator string

	if m.mode == ModeProjects {
		title = "🚀 TMUX PROJECT SESSIONIZER"
		help = "↑/↓: navigate • enter: create session • t: toggle to sessions • ctrl+r: refresh • q: quit"
		modeIndicator = modeStyle.Render("[ PROJECTS ]")
	} else {
		title = "📋 TMUX SESSION MANAGER"
		help = "↑/↓: navigate • enter: switch • ctrl+d: kill • t: toggle to projects • ctrl+r: refresh • q: quit"
		modeIndicator = modeStyle.Render("[ SESSIONS ]")
	}

	titleRendered := titleStyle.Render(title)
	helpRendered := helpStyle.Render(help)
	modeRendered := modeStyle.Render(modeIndicator)

	// Center the content
	content := lipgloss.JoinVertical(lipgloss.Center,
		titleRendered,
		modeRendered,
		"",
		m.list.View(),
		"",
		helpRendered,
	)

	// Center horizontally and vertically
	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, content)
}

func getProjectItems() []list.Item {
	var items []list.Item

	// Search paths matching your original script
	searchPaths := []string{
		filepath.Join(os.Getenv("HOME"), "dev"),
		filepath.Join(os.Getenv("HOME"), "personal"),
	}

	var projectItems []item

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

			// Match original script: mindepth 1, maxdepth 3
			// Skip hidden directories and node_modules
			if depth >= 1 && depth <= 3 &&
				!strings.HasPrefix(filepath.Base(path), ".") &&
				!strings.Contains(path, "node_modules") {
				name := filepath.Base(path)
				desc := strings.Replace(path, os.Getenv("HOME"), "~", 1)

				projectItems = append(projectItems, item{
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
	sort.Slice(projectItems, func(i, j int) bool {
		return projectItems[i].title < projectItems[j].title
	})

	// Convert to list items
	for _, item := range projectItems {
		items = append(items, item)
	}

	return items
}

func getSessionItems() []list.Item {
	var items []list.Item

	// Get tmux sessions
	cmd := exec.Command("tmux", "list-sessions", "-F", "#{session_name}:#{session_attached}:#{session_windows}")
	output, err := cmd.Output()
	if err != nil {
		// No sessions found
		return items
	}

	sessions := strings.Split(strings.TrimSpace(string(output)), "\n")
	var sessionItems []item

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

		sessionItems = append(sessionItems, item{
			title:       name,
			path:        name, // For sessions, path is the session name
			isSession:   true,
			isAttached:  attached,
			windowCount: windows,
		})
	}

	// Sort by name
	sort.Slice(sessionItems, func(i, j int) bool {
		return sessionItems[i].title < sessionItems[j].title
	})

	// Convert to list items
	for _, item := range sessionItems {
		items = append(items, item)
	}

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
		cmd := exec.Command("tmux", "new-session", "-s", selectedName, "-c", selectedPath)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	// Check if session already exists
	checkSession := exec.Command("tmux", "has-session", "-t="+selectedName)
	err := checkSession.Run()

	// If session doesn't exist, create it
	if err != nil {
		createCmd := exec.Command("tmux", "new-session", "-d", "-s", selectedName, "-c", selectedPath)
		if err := createCmd.Run(); err != nil {
			return fmt.Errorf("failed to create session: %v", err)
		}
	}

	// Switch to the session
	switchCmd := exec.Command("tmux", "switch-client", "-t", selectedName)
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

func main() {
	// Start with projects mode
	items := getProjectItems()

	if len(items) == 0 {
		fmt.Println("No directories found in ~/dev or ~/personal")
		os.Exit(1)
	}

	const defaultWidth = 80
	const listHeight = 15

	l := list.New(items, itemDelegate{}, defaultWidth, listHeight)
	l.Title = ""
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle
	l.Styles.PaginationStyle = helpStyle
	l.Styles.HelpStyle = helpStyle

	m := model{
		list: l,
		mode: ModeSessions,
	}

	// Start with sessions if they exist
	sessionItems := getSessionItems()
	if len(sessionItems) > 0 {
		m.list.SetItems(sessionItems)
	} else {
		m.mode = ModeProjects
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
		case "switch":
			err := switchTmuxSession(m.choice)
			if err != nil {
				fmt.Printf("Error switching to tmux session: %v\n", err)
				os.Exit(1)
			}
		case "kill":
			err := killTmuxSession(m.choice)
			if err != nil {
				fmt.Printf("Error killing tmux session: %v\n", err)
				os.Exit(1)
			} else {
				fmt.Printf("Session '%s' killed successfully\n", m.choice)
			}
		}
	}
}
