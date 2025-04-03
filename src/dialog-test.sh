#!/bin/bash

# Dialog Widget Showcase Script
# A comprehensive example script demonstrating all major dialog widgets
# Based on https://linux.die.net/man/1/dialog

# Set some variables for consistency
TITLE="Dialog Showcase"
BACKTITLE="Dialog Widget Examples"
WIDTH=75
HEIGHT=20

# Temp files for various operations
TEMP_DIR="/tmp/dialog_demo_$$"
TEMP_FILE="$TEMP_DIR/temp_file"
OUTPUT_FILE="$TEMP_DIR/output"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
    clear
    exit 0
}

# Trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Create a sample text file for text-related widgets
create_sample_file() {
    cat > "$TEMP_FILE" << EOF
# Dialog Widget Showcase - Sample File

This is a sample text file that will be used to demonstrate
various dialog widgets that require file input.

## Features demonstrated:
- Reading text files
- Editing content
- Monitoring changes
- File selection
- Directory navigation

Feel free to edit this file in the editbox example.
EOF
}

# Function to display a "press any key" message
press_any_key() {
    dialog --title "Continue" --pause "Press any key to continue..." 10 40 2
    return $?
}

# Main menu function
show_main_menu() {
    while true; do
        # Clear screen before showing menu
        clear
        
        # Show menu dialog
        dialog --clear --title "$TITLE" --backtitle "$BACKTITLE" \
               --cancel-label "Exit" --menu "Select a widget to demonstrate:" $HEIGHT $WIDTH 16 \
            1 "Msgbox - Basic message display" \
            2 "Yesno - Yes/No question" \
            3 "Infobox - Unblocking information" \
            4 "Inputbox - Basic text input" \
            5 "Passwordbox - Password input" \
            6 "Menu - Simple menu selection" \
            7 "Checklist - Multiple choice selection" \
            8 "Radiolist - Single choice from many" \
            9 "Gauge - Progress meter" \
            10 "Mixedgauge - Multiple component status" \
            11 "Editbox - Text file editor" \
            12 "Textbox - Text file viewer" \
            13 "Tailbox - File monitoring" \
            14 "Form - Multi-field form" \
            15 "Mixedform - Form with hidden fields" \
            16 "Inputmenu - Menu with editing" \
            17 "Calendar - Date selection" \
            18 "Timebox - Time selection" \
            19 "Dselect - Directory selection" \
            20 "Fselect - File selection" \
            21 "Colors & Styling - Display options" \
            2>&1 >/dev/tty > "$OUTPUT_FILE"
        
        # Get menu selection and exit status
        RET=$?
        [ -f "$OUTPUT_FILE" ] && choice=$(cat "$OUTPUT_FILE") || choice=""
        
        if [ $RET -ne 0 ]; then
            cleanup
        fi
        
        # Run the selected demo
        case $choice in
            1) demo_msgbox ;;
            2) demo_yesno ;;
            3) demo_infobox ;;
            4) demo_inputbox ;;
            5) demo_passwordbox ;;
            6) demo_menu ;;
            7) demo_checklist ;;
            8) demo_radiolist ;;
            9) demo_gauge ;;
            10) demo_mixedgauge ;;
            11) demo_editbox ;;
            12) demo_textbox ;;
            13) demo_tailbox ;;
            14) demo_form ;;
            15) demo_mixedform ;;
            16) demo_inputmenu ;;
            17) demo_calendar ;;
            18) demo_timebox ;;
            19) demo_dselect ;;
            20) demo_fselect ;;
            21) demo_colors ;;
            *) dialog --title "Error" --msgbox "Invalid selection" 10 40 ;;
        esac
        
        # Return to the main menu after each demo
        clear
        press_any_key
    done
}

# 1. Message Box widget
demo_msgbox() {
    dialog --title "Message Box Example" --backtitle "$BACKTITLE" \
           --msgbox "This is a basic message box.\n\nIt displays text and waits for the user to press OK." $HEIGHT $WIDTH
}

# 2. Yes/No widget
demo_yesno() {
    dialog --title "Yes/No Example" --backtitle "$BACKTITLE" \
           --yesno "Would you like to see the result of your choice?" $HEIGHT $WIDTH
    
    response=$?
    case $response in
        0) dialog --title "Result" --msgbox "You selected YES!" 10 40 ;;
        1) dialog --title "Result" --msgbox "You selected NO!" 10 40 ;;
        255) dialog --title "Result" --msgbox "You pressed ESC!" 10 40 ;;
    esac
}

# 3. Info Box widget
demo_infobox() {
    dialog --title "Info Box Example" --backtitle "$BACKTITLE" \
           --infobox "This is an info box.\nIt will disappear in 3 seconds...\n\nUnlike msgbox, it doesn't wait for user input." 10 50
    sleep 3
}

# 4. Input Box widget
demo_inputbox() {
    input=$(dialog --title "Input Box Example" --backtitle "$BACKTITLE" \
                  --inputbox "Please enter some text:" 10 50 "Default text" \
                  2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Your Input" --msgbox "You entered: '$input'" 10 50
    fi
}

# 5. Password Box widget
demo_passwordbox() {
    password=$(dialog --title "Password Box Example" --backtitle "$BACKTITLE" \
                     --passwordbox "Enter your password:" 10 50 \
                     2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Password Entered" --msgbox "Password entered! (Not shown for security)\nLength: ${#password} characters" 10 50
    fi
}

# 6. Menu widget
demo_menu() {
    selection=$(dialog --title "Menu Example" --backtitle "$BACKTITLE" \
                      --menu "Choose an option:" 15 50 6 \
                      "1" "Option One" \
                      "2" "Option Two" \
                      "3" "Option Three" \
                      "4" "Option Four" \
                      "5" "Option Five" \
                      2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Menu Selection" --msgbox "You selected option: $selection" 10 40
    fi
}

# 7. Checklist widget
demo_checklist() {
    selections=$(dialog --title "Checklist Example" --backtitle "$BACKTITLE" \
                       --checklist "Select multiple options:" 15 60 6 \
                       "1" "First option" off \
                       "2" "Second option" on \
                       "3" "Third option" off \
                       "4" "Fourth option" off \
                       "5" "Fifth option" on \
                       2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Checklist Selections" --msgbox "You selected: $selections" 10 60
    fi
}

# 8. Radiolist widget
demo_radiolist() {
    selection=$(dialog --title "Radiolist Example" --backtitle "$BACKTITLE" \
                      --radiolist "Select one option:" 15 50 6 \
                      "1" "First option" off \
                      "2" "Second option" on \
                      "3" "Third option" off \
                      "4" "Fourth option" off \
                      "5" "Fifth option" off \
                      2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Radiolist Selection" --msgbox "You selected: $selection" 10 50
    fi
}

# 9. Gauge widget
demo_gauge() {
    {
        # Loop to update gauge
        for i in {0..100..10}; do
            echo "$i"
            sleep 0.5
            
            # Change message halfway
            if [ $i -eq 50 ]; then
                echo "XXX"
                echo "$i"
                echo "Processing second half..."
                echo "XXX"
            fi
        done
        
        # Final message
        echo "XXX"
        echo "100"
        echo "Process completed!"
        echo "XXX"
        sleep 1
    } | dialog --title "Gauge Example" --backtitle "$BACKTITLE" \
               --gauge "Processing first half..." 10 60 0
}

# 10. Mixed Gauge widget
demo_mixedgauge() {
    dialog --title "Mixed Gauge Example" --backtitle "$BACKTITLE" \
           --mixedgauge "System Status Overview:" 20 70 60 \
           "CPU Usage" "30" \
           "Memory" "45" \
           "Disk Space" "10" \
           "Network" "Succeeded" \
           "Database" "Failed" \
           "Firewall" "OK" \
           "Backup" "Checking..." \
           "Updates" "Timeout" \
           "Services" "Skipped" \
           "Scan" "Unknown"
    
    sleep 3
}

# 11. Edit Box widget
demo_editbox() {
    create_sample_file
    
    edited_content=$(dialog --title "Edit Box Example" --backtitle "$BACKTITLE" \
                           --editbox "$TEMP_FILE" 20 70 \
                           2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        echo "$edited_content" > "$TEMP_FILE.edited"
        dialog --title "File Edited" --msgbox "File edited and saved to $TEMP_FILE.edited" 10 50
    fi
}

# 12. Text Box widget
demo_textbox() {
    create_sample_file
    
    dialog --title "Text Box Example" --backtitle "$BACKTITLE" \
           --textbox "$TEMP_FILE" 20 70
}

# 13. Tail Box widget
demo_tailbox() {
    # Create a file that updates
    {
        for i in {1..20}; do
            echo "Line $i: This is a sample log entry $(date)" >> "$TEMP_FILE.log"
            sleep 0.5
        done
    } &
    
    dialog --title "Tail Box Example" --backtitle "$BACKTITLE" \
           --tailbox "$TEMP_FILE.log" 20 70
    
    # Stop the background process
    kill $! 2>/dev/null
}

# 14. Form widget
demo_form() {
    form_data=$(dialog --title "Form Example" --backtitle "$BACKTITLE" \
                      --form "Please fill out this form:" 20 70 8 \
                      "Name:"            1 1  ""             1 15 30 0 \
                      "Email:"           2 1  ""             2 15 40 0 \
                      "Phone:"           3 1  ""             3 15 15 0 \
                      "Address:"         4 1  ""             4 15 40 0 \
                      "City:"            5 1  ""             5 15 20 0 \
                      "State/Province:"  6 1  ""             6 15 15 0 \
                      "Country:"         7 1  "USA"          7 15 20 0 \
                      2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        # Process the form data
        IFS=$'\n' read -rd '' -a fields <<< "$form_data"
        
        # Show results
        dialog --title "Form Results" --msgbox "Form submitted with data:\n\nName: ${fields[0]}\nEmail: ${fields[1]}\nPhone: ${fields[2]}\nAddress: ${fields[3]}\nCity: ${fields[4]}\nState: ${fields[5]}\nCountry: ${fields[6]}" 16 60
    fi
}

# 15. Mixed Form widget
demo_mixedform() {
    form_data=$(dialog --title "Mixed Form Example" --backtitle "$BACKTITLE" \
                      --mixedform "Enter login information:" 15 70 0 \
                      "Username:"        1 1  ""             1 15 30 40 0 \
                      "Password:"        2 1  ""             2 15 30 40 1 \
                      "Email:"           3 1  ""             3 15 30 40 0 \
                      "Account Type:"    4 1  "Standard"     4 15 20 0  2 \
                      2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        # Process the form data
        IFS=$'\n' read -rd '' -a fields <<< "$form_data"
        
        # Show results (mask password)
        dialog --title "Mixed Form Results" --msgbox "Form submitted with data:\n\nUsername: ${fields[0]}\nPassword: ********\nEmail: ${fields[1]}" 12 60
    fi
}

# 16. Input Menu widget
demo_inputmenu() {
    while true; do
        result=$(dialog --title "Input Menu Example" --backtitle "$BACKTITLE" \
                       --inputmenu "Select or rename an item:" 15 60 8 \
                       "1" "First option" \
                       "2" "Second option" \
                       "3" "Third option" \
                       "4" "Fourth option" \
                       "5" "Fifth option" \
                       2>&1 >/dev/tty)
        
        # Check if user cancelled
        if [ $? -ne 0 ]; then
            break
        fi
        
        # Process the selection
        case "$result" in
            RENAMED*)
                # Extract the tag and new value
                tag=$(echo "$result" | cut -d' ' -f2)
                new_value=$(echo "$result" | cut -d' ' -f3-)
                
                dialog --title "Item Renamed" \
                       --msgbox "Item $tag renamed to: $new_value" 8 50
                ;;
            *)
                # Regular selection
                dialog --title "Menu Selection" \
                       --msgbox "You selected item: $result" 8 50
                break
                ;;
        esac
    done
}

# 17. Calendar widget
demo_calendar() {
    # Get current date components
    current_day=$(date +%-d)
    current_month=$(date +%-m)
    current_year=$(date +%Y)
    
    date=$(dialog --title "Calendar Example" --backtitle "$BACKTITLE" \
                 --calendar "Select a date:" 0 0 \
                 $current_day $current_month $current_year \
                 2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Date Selected" --msgbox "You selected: $date" 10 40
    fi
}

# 18. Time Box widget
demo_timebox() {
    # Get current time components
    current_hour=$(date +%-H)
    current_min=$(date +%-M)
    current_sec=$(date +%-S)
    
    time=$(dialog --title "Time Box Example" --backtitle "$BACKTITLE" \
                 --timebox "Select a time:" 0 0 \
                 $current_hour $current_min $current_sec \
                 2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Time Selected" --msgbox "You selected: $time" 10 40
    fi
}

# 19. Directory Select widget
demo_dselect() {
    dir=$(dialog --title "Directory Select Example" --backtitle "$BACKTITLE" \
                --dselect "$HOME" 15 60 \
                2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "Directory Selected" --msgbox "You selected directory:\n$dir" 10 60
    fi
}

# 20. File Select widget
demo_fselect() {
    file=$(dialog --title "File Select Example" --backtitle "$BACKTITLE" \
                --fselect "$HOME/" 15 60 \
                2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        dialog --title "File Selected" --msgbox "You selected file:\n$file" 10 60
    fi
}

# 21. Colors and Styling
demo_colors() {
    dialog --title "Colors & Styling Example" --backtitle "$BACKTITLE" \
           --colors --msgbox "\Z1Red text\Zn, \Z2Green text\Zn, \Z3Yellow text\Zn, \Z4Blue text\Zn, \Z5Magenta text\Zn, \Z6Cyan text\Zn, \Z7White text\Zn, \Z0Black text\Zn\n\n\ZbBold text\Zn\n\ZuUnderlined text\Zn\n\ZrReverse text\Zn" 15 50
}

# Create sample file for text operations
create_sample_file

# Show welcome message
dialog --title "$TITLE" --backtitle "$BACKTITLE" \
       --msgbox "Welcome to the Dialog Widget Showcase!\n\nThis script demonstrates all major dialog widgets.\n\nClick OK to start." 12 50

# Show the main menu
show_main_menu