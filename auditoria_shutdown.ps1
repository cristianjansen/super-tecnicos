# Auditoria quem desligou o servidor

# Quem realizou o reboot e desligamento do servidor

# Defina o caminho do arquivo de saída
$outputFile = "C:\script\LogShutdown.txt"

# Filtra e obtém os eventos do log do sistema
$events = Get-EventLog System | Where-Object {$_.EventID -eq "1074" -or $_.EventID -eq "1076" -or $_.EventID -eq "6006"}

# Formata e escreve os eventos no arquivo de saída
$events | Select-Object Machinename, TimeWritten, UserName, EventID, Message | Format-Table -AutoSize -Wrap | Out-File -FilePath $outputFile

# Exibe uma mensagem indicando que a operação foi concluída
Write-Output "Eventos filtrados foram salvos em $outputFile."