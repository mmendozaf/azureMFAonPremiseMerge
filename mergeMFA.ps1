$users = Import-Csv $args[0]
Write-Host "Found $($users.Count) users"
$total=$($users.Count)
$filenameFormat = $args[0]+"-" + (Get-Date -Format "yyyyMMddmm") + ".csv"
#Write-Host "$filenameFormat"
$currentuser=1
$out = ("Username;DN;UPN;email;enabled;manager;AZperUserMFA;AZdefaultMFA;AZpriPhone;AZaltPhone;OnMFAPriPhone;OnMFABCKPhone;OnMFAMode")
Write-Output $out |  Out-File -FilePath $filenameFormat  
Write-Output "Conneting to Azure"
Connect-MsolService
Write-Output "Conneting to Active Directory"
$c= Get-Credential

$Results = @()

        ForEach ($u in $users) {
            
            Write-Host "User $currentuser from $total"
            $retry = 1
            $r = 0
            $out = @()
            #clear on-premise ad attribute variables
            $user = $dn = $upn = $email = $enabled = $manager = ""
            #clear azure ad attribute variables
            $msol = $perUser = $defaultMethod = $phone = $priPh = $altPhone = $altPh = $out = ""
            
            While ($r -lt $retry) {
                Try {
                    #Write-Host $u.Username
                    $user = Get-ADUser -Credential $c $u.Username -Properties UserPrincipalName,EmailAddress,Enabled,Manager -ErrorAction Stop
                    $dn = $user.DistinguishedName
                    $upn = $user.UserPrincipalName
                    $email = ($user).EmailAddress
                    $enabled = If ($user.Enabled) {"Enabled"} Else {"Disabled"}
                    $manager = ($user).Manager
                    #$out = ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}" -f $dn,$u.Username,$upn,$email,$enabled,$manager,$perUser,$defaultMethod,$priPh,$altPh,)
                    $r = $retry
                }
                Catch {
                    $err = $_
                    $r++
                    If ($r -eq $retry) {
                        $dn="NOT_FOUND"
                    }
                    Else {
                        $rnd = Get-Random -Minimum 1 -Maximum 2
                        Start-Sleep -Seconds $rnd
                    }
                }
            }
                
                If ($upn -ne "") {
                $msol = Get-MsolUser -userprincipalname $upn | Select StrongAuthenticationRequirements,StrongAuthenticationMethods,StrongAuthenticationUserDetails
                $perUser = If ($msol.StrongAuthenticationRequirements.State -eq $null) { "Disabled" } Else { $msol.StrongAuthenticationRequirements.State }
                $defaultMethod = $msol.StrongAuthenticationMethods | ? { $_.IsDefault } | Select -ExpandProperty MethodType
                $phone = $msol.StrongAuthenticationUserDetails.PhoneNumber
                $altPhone = $msol.StrongAuthenticationUserDetails.AlternativePhoneNumber
                If ($phone -ne $null) {
                    $priPh = [String]$phone -replace " ","" 
                }
                
                If ($altPhone -ne $null) {
                    $altPh = [String]$altPhone  -replace " ",""
                }
               
                
                }
                
                $out = ("{0};{1};{2};{3};{4};{5};{6};{7};{8};{9};+{10}{11};+{12}{13};{14}" -f $u.Username,$dn,$upn,$email,$enabled,$manager,$perUser,$defaultMethod,$priPh,$altPh,$u."Primary Country Code",$u."Primary Phone",$u."Backup Country Code",$u."Backup Phone",$u.Mode)
                Write-Output $out |  Out-File -FilePath $filenameFormat -Append 
                $currentuser++

            
            }