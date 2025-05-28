#!/usr/bin/env bash
# tests/lib/progress-display.sh
# Real-time progress display for parallel test execution

# Source utilities
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/utils.sh"

# Global variables for progress tracking
declare -g PROGRESS_MODE="simple"
declare -g TERMINAL_WIDTH=80
declare -g PROGRESS_ACTIVE=false
declare -g LAST_UPDATE_TIME=0

# Initialize progress display
init_progress_display() {
    local show_progress="${1:-true}"
    
    if [[ "$show_progress" != "true" ]]; then
        PROGRESS_MODE="none"
        return 0
    fi
    
    # Detect terminal capabilities
    if supports_fancy_output; then
        PROGRESS_MODE="fancy"
        TERMINAL_WIDTH=$(get_terminal_width)
        
        # Save terminal state (ignore failures) - use subshell for safety
        if ! (bash -c 'tput smcup' 2>/dev/null); then
            PROGRESS_MODE="simple"
        fi
        
        # Hide cursor (ignore failures) - use subshell for safety
        (bash -c 'tput civis' 2>/dev/null) || true
        
        # Setup cleanup trap only if fancy mode succeeded
        if [[ "$PROGRESS_MODE" == "fancy" ]]; then
            trap cleanup_progress_display EXIT
        fi
        
        # Clear screen (ignore failures) - use subshell for safety
        (bash -c 'tput clear' 2>/dev/null) || true
    else
        PROGRESS_MODE="simple"
    fi
    
    PROGRESS_ACTIVE=true
    log_debug "Progress display initialized in $PROGRESS_MODE mode"
}

# Cleanup progress display
cleanup_progress_display() {
    if [[ "$PROGRESS_MODE" == "fancy" ]]; then
        # Show cursor - use subshell for safety
        (bash -c 'tput cnorm' 2>/dev/null) || true
        # Restore terminal state - use subshell for safety
        (bash -c 'tput rmcup' 2>/dev/null) || true
    fi
    PROGRESS_ACTIVE=false
}

# Update progress display
update_progress_display() {
    [[ "$PROGRESS_ACTIVE" != "true" ]] && return 0
    
    local started="$1"
    local running="$2" 
    local completed="$3"
    local failed="$4"
    local queued="$5"
    shift 5
    local current_tests=("$@")
    
    # Throttle updates to avoid flickering
    local current_time=$(date +%s)
    if [[ $((current_time - LAST_UPDATE_TIME)) -lt 1 ]] && [[ "$PROGRESS_MODE" == "fancy" ]]; then
        return 0
    fi
    LAST_UPDATE_TIME=$current_time
    
    case "$PROGRESS_MODE" in
        "fancy")
            draw_fancy_progress_display "$started" "$running" "$completed" "$failed" "$queued" "${current_tests[@]}"
            ;;
        "simple")
            draw_simple_progress_display "$started" "$running" "$completed" "$failed"
            ;;
        "none")
            # No output
            ;;
    esac
}

# Simple progress display for non-interactive terminals
draw_simple_progress_display() {
    local started="$1" running="$2" completed="$3" failed="$4"
    local total=$((started + running + completed + failed))
    local percent=0
    
    if [[ $total -gt 0 ]]; then
        percent=$(( (completed + failed) * 100 / total ))
    fi
    
    printf "\r[%3d%%] Started: %d, Running: %d, Completed: %d, Failed: %d" \
           "$percent" "$started" "$running" "$completed" "$failed"
}

# Fancy progress display with full UI
draw_fancy_progress_display() {
    local started="$1" running="$2" completed="$3" failed="$4" queued="$5"
    shift 5
    local current_tests=("$@")
    
    local total=$((started + running + completed + failed + queued))
    local percent=0
    local passed=$((completed - failed))
    
    if [[ $total -gt 0 ]]; then
        percent=$(( (completed + failed) * 100 / total ))
    fi
    
    # Clear screen and position cursor - use subshells for safety
    (bash -c 'tput clear' 2>/dev/null) || true
    (bash -c 'tput cup 0 0' 2>/dev/null) || true
    
    # Calculate box width based on terminal
    local box_width=$((TERMINAL_WIDTH > 80 ? 80 : TERMINAL_WIDTH - 2))
    local content_width=$((box_width - 4))
    
    # Draw header
    draw_box_line "top" "$box_width"
    draw_box_content "CleanSumStats Test Suite - Parallel Execution" "$box_width"
    draw_box_line "middle" "$box_width"
    
    # Draw progress bar
    local progress_text="Progress: "
    local progress_bar_width=$((content_width - ${#progress_text} - 15))  # Space for percentage and counts
    local progress_line="${progress_text}$(draw_progress_bar "$percent" "$progress_bar_width") ${percent}% (${completed}/${total})"
    draw_box_content "$progress_line" "$box_width"
    
    # Empty line
    draw_box_content "" "$box_width"
    
    # Status counters with emojis
    local status_line1="Status:  🟢 Started: ${started}  🔵 Running: ${running}  ✅ Passed: ${passed}"
    local status_line2="         ❌ Failed: ${failed}   ⏸️  Queued: ${queued}   ⏱️  ETA: $(calculate_eta_display "$completed" "$total")"
    draw_box_content "$status_line1" "$box_width"
    draw_box_content "$status_line2" "$box_width"
    
    # Empty line
    draw_box_content "" "$box_width"
    
    # Currently running tests
    draw_box_content "Currently Running:" "$box_width"
    local i=0
    for test in "${current_tests[@]}"; do
        if [[ $i -lt 3 ]]; then  # Show max 3 running tests
            local duration=$(get_test_duration "$test")
            local test_line="• ${test} (${duration})"
            draw_box_content "$test_line" "$box_width"
        fi
        ((i++))
    done
    
    # Fill remaining lines for running tests
    for ((j=i; j<3; j++)); do
        draw_box_content "" "$box_width"
    done
    
    # Recent completions (if any)
    if [[ $completed -gt 0 ]]; then
        draw_box_content "" "$box_width"
        draw_box_content "Recent Completions:" "$box_width"
        show_recent_completions "$box_width" 2
    fi
    
    # Bottom border
    draw_box_line "bottom" "$box_width"
    
    # Flush output
    printf "\n"
}

# Draw box border lines
draw_box_line() {
    local type="$1"
    local width="$2"
    
    case "$type" in
        "top")
            printf "┌"
            for ((i=1; i<width-1; i++)); do printf "─"; done
            printf "┐\n"
            ;;
        "middle")
            printf "├"
            for ((i=1; i<width-1; i++)); do printf "─"; done
            printf "┤\n"
            ;;
        "bottom")
            printf "└"
            for ((i=1; i<width-1; i++)); do printf "─"; done
            printf "┘"
            ;;
    esac
}

# Draw box content with proper padding
draw_box_content() {
    local content="$1"
    local box_width="$2"
    local content_width=$((box_width - 4))
    
    # Truncate content if too long
    if [[ ${#content} -gt $content_width ]]; then
        content="${content:0:$((content_width-3))}..."
    fi
    
    # Calculate padding
    local padding=$((content_width - ${#content}))
    
    printf "│ %s%*s │\n" "$content" "$padding" ""
}

# Draw progress bar
draw_progress_bar() {
    local percent="$1"
    local width="$2"
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "]"
}

# Get test duration for display
get_test_duration() {
    local test_name="$1"
    local status_file="${SESSION_LOG_DIR:-}/status/${test_name}.status"
    local start_file="${SESSION_LOG_DIR:-}/status/${test_name}.start"
    
    if [[ -f "$start_file" ]]; then
        local start_time=$(cat "$start_file" 2>/dev/null || echo "0")
        local current_time=$(get_timestamp)
        local duration=$((current_time - start_time))
        format_duration "$duration"
    else
        echo "0s"
    fi
}

# Calculate and format ETA for display
calculate_eta_display() {
    local completed="$1"
    local total="$2"
    
    if [[ $completed -eq 0 ]] || [[ ! -f "${SESSION_LOG_DIR:-}/timing.log" ]]; then
        echo "calculating..."
        return
    fi
    
    # Calculate average duration from completed tests
    local avg_duration=0
    local count=0
    
    while IFS=',' read -r test_name duration; do
        if [[ -n "$duration" ]] && [[ "$duration" =~ ^[0-9]+$ ]]; then
            avg_duration=$((avg_duration + duration))
            ((count++))
        fi
    done < "${SESSION_LOG_DIR:-}/timing.log" 2>/dev/null
    
    if [[ $count -gt 0 ]]; then
        avg_duration=$((avg_duration / count))
        calculate_eta "$completed" "$total" "$avg_duration"
    else
        echo "calculating..."
    fi
}

# Show recent test completions
show_recent_completions() {
    local box_width="$1"
    local max_items="${2:-3}"
    local completions_file="${SESSION_LOG_DIR:-}/completions.log"
    
    if [[ ! -f "$completions_file" ]]; then
        return
    fi
    
    # Show last few completions
    tail -n "$max_items" "$completions_file" 2>/dev/null | while IFS=',' read -r test_name status duration; do
        local icon="✅"
        [[ "$status" == "failed" ]] && icon="❌"
        local completion_line="${icon} ${test_name} ($(format_duration "$duration")) - ${status^^}"
        draw_box_content "$completion_line" "$box_width"
    done
}

# Log test completion for recent completions display
log_test_completion() {
    local test_name="$1"
    local status="$2"  # "passed" or "failed"
    local duration="$3"
    
    local completions_file="${SESSION_LOG_DIR:-}/completions.log"
    echo "${test_name},${status},${duration}" >> "$completions_file"
    
    # Keep only last 10 completions
    if [[ -f "$completions_file" ]]; then
        tail -n 10 "$completions_file" > "${completions_file}.tmp" && mv "${completions_file}.tmp" "$completions_file"
    fi
}

# Log test timing for ETA calculation
log_test_timing() {
    local test_name="$1"
    local duration="$2"
    
    local timing_file="${SESSION_LOG_DIR:-}/timing.log"
    echo "${test_name},${duration}" >> "$timing_file"
}

# Record test start time
record_test_start() {
    local test_name="$1"
    local start_time="$(get_timestamp)"
    local start_file="${SESSION_LOG_DIR:-}/status/${test_name}.start"
    
    mkdir -p "$(dirname "$start_file")"
    echo "$start_time" > "$start_file"
}

# Final progress summary
show_final_summary() {
    local total="$1"
    local passed="$2"
    local failed="$3"
    local duration="$4"
    
    cleanup_progress_display
    
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    Test Execution Summary"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    printf "  Total Tests: %d\n" "$total"
    printf "  Passed:      %d (%.1f%%)\n" "$passed" "$(echo "scale=1; $passed * 100 / $total" | bc -l 2>/dev/null || echo "0")"
    printf "  Failed:      %d (%.1f%%)\n" "$failed" "$(echo "scale=1; $failed * 100 / $total" | bc -l 2>/dev/null || echo "0")"
    printf "  Duration:    %s\n" "$(format_duration "$duration")"
    echo
    
    if [[ $failed -eq 0 ]]; then
        log_success "All tests passed! 🎉"
    else
        log_error "$failed test(s) failed"
        echo "  Check logs in: ${SESSION_LOG_DIR:-tests/test_logs/latest}"
    fi
    
    echo "═══════════════════════════════════════════════════════════════"
} 