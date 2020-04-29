Clear-Host
Remove-Variable * -ErrorAction SilentlyContinue #Remove all variables from last run

#Load required Assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

function get_address([string]$line){ #Get the path for the executable from the document
    $split_line = $line.split("`"")
    $path = $split_line[1]
    return $path
}

function get_date(){
    return Get-Date -Format ShortDatePattern #| Out-String
}

function get_time(){
    return Get-Date -Format ShortTimePattern #| Out-String
}

#===========================================================
#    VARIABLES
#===========================================================
#$testname_array = @() #holds variable names for each of the created checkboxes
#$arg_array = @() #holds the variable names for each of the created text boxes
$path_array = @() #Holds the EXE path for each selftest
$name_array = @() #Holds the name of the test
$entered_args = @()# Takes the arguments from each text box and holds for use in executable
$iter = 0 #iterator
$lines = 0 # Num of lines in the doc
$error_count = 0 # Number of tests with return codes of anything other than 0

#Get number of lines in a text document in variable $doc_length
Set-Location $PSScriptRoot
$doc = Get-Content -Path '.\gui_template.txt' #get the text file 

foreach($line in $doc){ #Split the lines in the doc and get the name and executable, as well as # of lines
    if($line -ne ""){
        $split_line = $line.split(' ')
        $name_array += $split_line[0]
        $path_array += get_address($line)
        $lines++
    }
    
}

#===========================================================
#            GUI CREATION
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
$run_button.Location = New-Object System.Drawing.Point(425, 75)
$run_button.Width = 150
$run_button.Height = 50
$run_button.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Italic)
$main_form.Controls.Add($run_button)

#Logging textbox
$log_path = New-Object System.Windows.Forms.TextBox
$log_path.Text = ""
$log_path.Location = New-Object System.Drawing.Point (530, 40)
$log_path.Width = 300
#$log_path.ScrollBars = New-Object System.Windows.Forms.ScrollBar("Horizontal")
$main_form.Controls.Add($log_path)

#Textbox autofiller

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

#LogFile path label
$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "Log File Path"
$logLabel.Location = New-Object System.Drawing.Point (425, 40)
$logLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$logLabel.Width = 100 
$logLabel.Height = 30
$main_form.Controls.Add($logLabel)

#create all checkboxes and textboxes
for($i = 0; $i -lt $lines; $i++){
    #titles (saved as test_[i])
    New-Object System.Windows.Forms.Checkbox | `
    Set-Variable -Name ("test_" + $i)
    #$testname_array += ("$test_" + $i) 

    #arg boxes (saved as arguments_[i])
    New-Object System.Windows.Forms.TextBox | `
    Set-Variable -Name ("arguments_" + $i)
    #$arg_array += ("$arguments_" + $i)
}

#Properties to checkboxes
[int]$iter = 0 #Spaces out GUI evenly
Get-Variable -name test_* -ValueOnly | ForEach-Object {
   $_.Text = $name_array[$iter]
   $_.Location = New-Object System.Drawing.Point (30, (38 + 30*$iter))
   $_.Width = 100
   $_.Height = 30
   $iter++
}

#Properties to TextBoxes
[int]$iter = 0 #Spaces out GUI evenly
Get-Variable -name arguments_* -ValueOnly | ForEach-Object {
   $_.Location = New-Object System.Drawing.Point (130, (40 + 30*$iter))
   $_.Width = 250
   $_.Height = 50
   $_.Visible = $TRUE
   $iter++
}


#Add buttons along the x-value of 300
get-variable -Name test_* -ValueOnly | ForEach-Object {
    $main_form.Controls.Add($_)
}

Get-Variable -Name arguments_* -ValueOnly | ForEach-Object {
    $main_form.Controls.Add($_)
}


#--------------------------------------------------------------------

#===================================================================
#        GUI COMMANDS
#===================================================================

#---------------------------------------------------------------------

$run_button.Add_Click({
    #check log path
    if($log_path.Text -eq ""){
        $log_path.Text = $PSScriptRoot + "\test_log.txt"
    }

    #Start Log:
    $time = get_time
    $date = get_date
    "Test started on " + $date + " at " + $time + "`n"| Out-File -FilePath $log_path.Text -Append

    #Get arguments from each text box 
    Get-Variable -Name arguments_* -ValueOnly | ForEach-Object {
            $holder= $_.Text
            $entered_args += $holder 
    }

    #Find selected checkboxes
    $iter = 0
    Get-Variable -name test_* -ValueOnly | ForEach-Object {
        
        if($_.Checked){
            #Get arguments from table and run exe
            Start-Process $path_array[$iter] -ArgumentList $entered_args[$iter] | Wait-Process
            $return_val = $LASTEXITCODE
            if($return_val -ne 0){
                #log failure
                #$timestamp + "`t" + $name_array[$iter] + " FAILED!" | Add-Content -path $log_path.Text
                $text_string = "`t" + $name_array[$iter] + " FAILED!" #Get values into one string
                Add-Content -path $log_path.Text -Value $text_string 
                "`t" + $name_array[$iter] + " Error Code: " + $return_val | Out-File -FilePath $log_path.Text -Append

            }else{
                #log success
                $text_string = "`t" + $name_array[$iter] + " PASSED!" #Get values into one string
                Add-Content -path $log_path.Text -Value $text_string
            }
        }
        $iter++
    }

})

[void]$main_form.ShowDialog()
# 1 2 selftest "C:\Users\klepeter\Documents\PeterK_Local\CIATE\Powershell GUI\LogFile.txt"