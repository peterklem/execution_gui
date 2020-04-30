# For help , reference the README in westeros:8080 http://westeros:8080/tfs/InstrumentsAndApplications/QA/_versionControl?path=%24%2FQA%2FCIATE%2FTools%20and%20Utilities%2FPowerShell%20Program%20Runner

Clear-Host
Remove-Variable * -ErrorAction SilentlyContinue #Remove all variables from last run


#Load required Assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

function get_address([string]$line){ #Get the path for the executable from the document
    $split_line = $line.split("`"")
    $path = $split_line[1]
    return $path
}

function get_date(){ #Gets date in format below 
    return get-date -format "MM/dd/yy"
}

function get_time(){ #Gets time in format below
    return get-date -format "hh:mm:ss"
}

#===========================================================
#    VARIABLES
#===========================================================

$path_array = @() #Holds the EXE path for each selftest
$name_array = @() #Holds the name of the test
$entered_args = @()# Takes the arguments from each text box and holds for use in executable
$loop_array = @() # Stores # of loops
$iter = 0 #iterator 
$lines = 0 # Num of lines in the doc
$error_count = 0 # Number of tests with return codes of anything other than 0

Set-Location $PSScriptRoot

# TEXT FILE SAVED HERE
#--------------------------------------------------------------------------------
$doc = Get-Content -Path '.\gui_template.txt' #get the text file 
#--------------------------------------------------------------------------------

foreach($line in $doc){ #Split the lines in the doc and get the name and executable, and get # of lines
    if($line -ne ""){
        $split_line = $line.split(' ')
        $name_array += $split_line[0]
        $path_array += get_address($line)
        $lines++
    }
    
}

#===========================================================
#            GUI CREATION/SETUP
#===========================================================
#------------------------------------------------------------------
#Start main formS
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = 'CIATE Test Selector'
$main_form.Width = 200
$main_form.Height = 200
$main_form.AutoSize = $true

# Execute button
$run_button = New-Object System.Windows.Forms.Button
$run_button.Text = 'Run Tests'
$run_button.Location = New-Object System.Drawing.Point(550, 75)
$run_button.Width = 150
$run_button.Height = 50
$run_button.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Italic)
$main_form.Controls.Add($run_button)

#Help button
$help_button = New-Object System.Windows.Forms.Button
$help_button.Text = "Help"
$help_button.Location = New-Object System.Drawing.Point (900, 10)
$help_button.Width = 40
$help_button.Height = 20
$main_form.Controls.Add($help_button)

#Logging textbox
$log_path = New-Object System.Windows.Forms.TextBox
$log_path.Text = ""
$log_path.Location = New-Object System.Drawing.Point (610, 40)
$log_path.Width = 300
#$log_path.ScrollBars = New-Object System.Windows.Forms.ScrollBar("Horizontal")
$main_form.Controls.Add($log_path)

#Textbox autoselect button
$select_file = New-Object System.Windows.Forms.Button
$select_file.Text = '...'
$select_file.Location = New-Object System.Drawing.Point(910, 39)
$select_file.Width = 30
$select_file.Height = 22
$select_file.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$main_form.Controls.Add($select_file)

#Test Label
$testLabel = New-Object System.Windows.Forms.Label
$testLabel.Text = "Test Type"
$testLabel.Location = New-Object System.Drawing.Point (30,10)
$testLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
$testLabel.Width = 75
$testLabel.Height = 30
$main_form.Controls.Add($testLabel)

#Argument label
$argLabel = New-Object System.Windows.Forms.Label
$argLabel.Text = "Arguments"
$argLabel.Location = New-Object System.Drawing.Point ( 125, 10)
$argLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
$argLabel.Width = 100 
$argLabel.Height = 30
$main_form.Controls.Add($argLabel)

#Looping label
$loopLabel = New-Object System.Windows.Forms.Label
$loopLabel.Text = "Loops"
$loopLabel.Location = New-Object System.Drawing.Point ( 400, 10)
$loopLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
$loopLabel.Width = 100 
$loopLabel.Height = 30
$main_form.Controls.Add($loopLabel)

#LogFile path label
$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "Log File Path"
$logLabel.Location = New-Object System.Drawing.Point (530, 40)
$logLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$logLabel.Width = 100 
$logLabel.Height = 30
$main_form.Controls.Add($logLabel)

#create all checkboxes and textboxes
for($i = 0; $i -lt $lines; $i++){
    #titles (saved as test_[i])
    New-Object System.Windows.Forms.Checkbox | `
    Set-Variable -Name ("test_" + $i)

    #arg boxes (saved as arguments_[i])
    New-Object System.Windows.Forms.TextBox | `
    Set-Variable -Name ("arguments_" + $i)

    #loop boxes
    New-Object System.Windows.Forms.TextBox | `
    Set-Variable -Name ("loops_" + $i)
}

#Properties for auto-generated checkboxes
[int]$iter = 0 #Used for GUI spacing
Get-Variable -name test_* -ValueOnly | ForEach-Object { #Loop through "test" variables
   $_.Text = $name_array[$iter]
   $_.Location = New-Object System.Drawing.Point (30, (38 + 30*$iter))
   $_.Width = 100
   $_.Height = 30
   $main_form.Controls.Add($_)
   $iter++
}

#Properties for auto-generated argument text boxes
[int]$iter = 0 #Used for GUI spacing
Get-Variable -name arguments_* -ValueOnly | ForEach-Object { #Loop through "arguments" variables
   $_.Location = New-Object System.Drawing.Point (130, (40 + 30*$iter))
   $_.Width = 250
   $_.Height = 50
   $_.Visible = $TRUE
   $main_form.Controls.Add($_)
   $iter++
   
}

#Properties for auto-generated looping text boxes
[int]$iter = 0 #Used for GUI spacing
Get-Variable -name loops_* -ValueOnly | ForEach-Object { #Loop through "loop" variables
   $_.Location = New-Object System.Drawing.Point (400, (40 + 30*$iter))
   $_.Width = 75
   $_.Height = 50
   $_.Visible = $TRUE
   $_.Text = "1"
   $main_form.Controls.Add($_)
   $iter++
   
}
<#
#get-variable -Name test_* -ValueOnly | ForEach-Object {
    #$main_form.Controls.Add($_)
#}

Get-Variable -Name arguments_* -ValueOnly | ForEach-Object {
    #$main_form.Controls.Add($_)
}
#>



#--------------------------------------------------------------------

#===================================================================
#        GUI COMMANDS/BUTTON PRESSES
#===================================================================

#---------------------------------------------------------------------
$select_file.Add_Click({ # Select file button pressed
    #Add-Type -AssemblyName System.Windows.Forms
    $f = new-object Windows.Forms.OpenFileDialog
    $f.InitialDirectory = $PSScriptRoot
    $f.Filter = "Text Files (*.txt)|*.txt"
    $f.ShowHelp = $true
    $f.Multiselect = $false
    [void]$f.ShowDialog()
    $log_path.Text = $f.Filename
})


$run_button.Add_Click({ #Run tests button pressed
    #check log path
    if($log_path.Text -eq ""){ # If no log path inputted
        $log_path.Text = $PSScriptRoot + "\test_log.txt" #
    }

    #Start Log:
    $time = get_time
    $date = get_date
    "EXECUTION STARTED " + $date + " AT " + $time + "`n"| Out-File -FilePath $log_path.Text -Append

    #Get arguments from each text box 
    Get-Variable -Name arguments_* -ValueOnly | ForEach-Object {
            $holder= $_.Text
            $entered_args += $holder 
    }

    #Get arguments for each loop box
    Get-Variable -Name loops_* -ValueOnly | ForEach-Object {
            $int_holder= $_.Text -as [int]
            if($int_holder -eq "" -or $int_holder -le 0){ #If loop count not specified or bad value
                $int_holder = 1
            }
            $loop_array += $int_holder #append to array
    }

    #Find selected checkboxes
    $iter = 0
    
    Get-Variable -name test_* -ValueOnly | ForEach-Object {
        
        if($_.Checked){ #Check status of current checkbox

            for($i = 0; $i -lt $loop_array[$iter]; $i++){ # Check loop array for # of times to run test
                #Get arguments from table and run exe
                $process = Start-Process $path_array[$iter] -ArgumentList $entered_args[$iter] -PassThru
                #$handle = $proc.Handle # cache proc.Handle
                $process.WaitForExit();
                $error_code = $process.ExitCode #save exit code
                

                #Log the returned value to the log file
                $time = get_time
                $log_entry = $time + "`t" + $name_array[$iter] + " returned value: " + $error_code 
                $log_entry | Out-File -FilePath $log_path.Text -Append
            }
            
            
        }
        $iter++
    }

})

$help_button.Add_Click({ #Help button is clicked
    cd $PSScriptRoot
    Start-Process 'C:\Windows\system32\notepad.exe' -ArgumentList '.\README.txt'
})

[void]$main_form.ShowDialog()