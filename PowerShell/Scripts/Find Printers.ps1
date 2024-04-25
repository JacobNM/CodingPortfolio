Get-WmiObject -class win32_printer |
 Select-Object name,
 @{n="Default?";e={if($_.attributes -band 4){$attr="default"};$attr}},
 @{n="Shared?";e={if($_.attributes -band 8){$attr="shared"};$attr}},
 @{n="Status";e={switch($_.printerstatus){1{$stat="other"}
 2{$stat="unknown"}
 3{$stat="idle"}
 4{$stat="printing"}
 5{$stat="warming up"}
 6{$stat="stopped printing"}
 7{$stat="offline"}};
 $stat}} |
 Format-Table -AutoSize