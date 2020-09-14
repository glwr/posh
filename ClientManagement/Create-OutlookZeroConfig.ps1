
if(!(Get-Item HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover))
{
    "Create Item Path"
    New-Item -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\ -Name AutoDiscover -Force
}
if(!(Get-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover -Name "ZeroConfigExchange"))
{
    "Create ItemProperty"
    New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover -Name "ZeroConfigExchange" -Value 1 -PropertyType DWORD -Force
}
else
{
    "Remove and Create new ItemProperty"
    Remove-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover -Name "ZeroConfigExchange"
    New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover -Name "ZeroConfigExchange" -Value 1 -PropertyType DWORD -Force
}
Read-Host "Please press any key to end execution"