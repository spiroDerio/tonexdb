This is just a draft code example. But it works.

Execute-SQLCopy -sInsertTable "ToneModels" -sNewDatabase $newDB  -sDefaultDB $allDB  -sSQLCMD $cmdSearch

This copies the models selection "-sSQLCMD $cmdSearch" from master DB "sDefaultDB $allDB" into "-sNewDatabase $newDB"
