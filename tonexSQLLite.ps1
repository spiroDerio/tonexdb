$scriptfolder = Get-Location
$DefaultDB = $scriptfolder.path+"\Default\Library.db"
$newDB = $scriptfolder.path+"\Processed\Library.db"
$allDB = $scriptfolder.path+"\ToProcess\All Tonenet until 2023 nov 30.db"
$assemblyFile = $scriptfolder.path+"\System.Data.SQLite.dll"

$global:DBOpen = $false

[Reflection.Assembly]::LoadFile($assemblyFile) 

Function Execute-SQL {
    Param(
        [string]$sDatabasePath,
        [string]$sSQLCMD
    )
    Process
    {
        $rows = 0
        $scon = New-Object System.Data.SQLite.SQLiteConnection
        $scon.ConnectionString = 'Data Source="'+ $sDatabasePath +'";Version=3;'
        $cmd = New-Object System.Data.SQLite.SQLiteCommand
        $cmd.Connection = $scon
        $cmd.CommandText = $sSQLCMD
        $cmd.CommandTimeout = 0
        $scon.Open()
        $rows = $cmd.ExecuteNonQuery()
        $scon.Dispose()
        $cmd.Dispose()
        return $rows
    }
}

Function Execute-SQLCopy{
    Param(
        [string]$sDefaultDB,
        [string]$sSQLCMD,
        [string]$sInsertTable,
        [string]$sNewDatabase
    )
    Process
    {   
        $connString = 'Data Source="'+ $sDefaultDB +'";Version=3;'
        $sqlCommand = $sSQLCMD
        $conn = New-Object -TypeName System.Data.SQLite.SQLiteConnection
        $conn.ConnectionString = $connString
        $conn.Open()
        $cmd = New-Object -TypeName System.Data.SQLite.SQLiteCommand
        $cmd.CommandText = $sqlCommand
        $cmd.Connection = $conn
        $reader=$cmd.ExecuteReader()
        $tblHeader=@()
        for ($i=0;$i -lt $reader.FieldCount;$i++) {
            $tblHeader += $reader.GetName($i)
        }
        while ($reader.read()) {
            $insert = 'INSERT INTO '+ $sInsertTable +'('
            $insert += '"' + ($tblHeader -join '","' ) + '"'
            $insert += ')'
            $values = New-Object System.Collections.ArrayList
            for($i=0;$i -lt $reader.FieldCount;$i++)
            {
                $values.add($reader[$i]) 
            }
            $insert += 'VALUES(' 
            $insert += "'" + ($values -join "'"+","+"'" ) + "'"    
            $insert +=')'
            try{
                Execute-SQL -sDatabasePath $sNewDatabase -sSQLCMD $insert
            }catch{
                #[System.IO.FileNotFoundException]
                $_.Exception.message
                Write-Warning $_.Exception.Message 
                 Write-Warning $_.CategoryInfo
  Write-Warning $_.FullyQualifiedErrorId
  Write-Warning ($_.ScriptStackTrace -replace '^')
                Write-Host "Error on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
            }
            Clear-Variable insert 
        }
        #$rows.SyncRoot | Out-GridView
        $cmd.Dispose()
        $conn.Dispose() 
    }
}

Function Execute-SQLRead {
    Param(
        [string]$sDatabasePath,
        [string]$sSQLCMD
    )
    Process
    {   
        $connString = 'Data Source="'+ $sDatabasePath +'";Version=3;'
        $sqlCommand = $sSQLCMD
        $conn = New-Object -TypeName System.Data.SQLite.SQLiteConnection
        $conn.ConnectionString = $connString
        $conn.Open()
        $cmd = New-Object -TypeName System.Data.SQLite.SQLiteCommand
        $cmd.CommandText = $sqlCommand
        $cmd.Connection = $conn
        $reader=$cmd.ExecuteReader()
        $rows = @()
        while ($reader.read()) {
            $columns = New-Object psobject
            for($i=0;$i -lt $reader.FieldCount;$i++)
            {
                $columns | Add-Member -type NoteProperty -name $reader.GetName($i) -value $reader[$i]
            }
            $rows +=$columns
        }
        #$rows.SyncRoot | Out-GridView
        $cmd.Dispose()
        $conn.Dispose()
        return $rows
    }
}

Function GetColumnAndType{
   # PRAGMA table_info(Presets);
}


Function Create-NewDB{
    Param(
        [string]$sDefaultDB,
        [string]$sNewDatabase
  
    )
    Process
    {  
$cmdGetSQLSchema =@'
SELECT sql FROM sqlite_master WHERE type='table'
'@
    $TonexTblSchemas = @()
    $TonexTblSchemas = Execute-SQLRead -sDatabasePath $sDefaultDB  -sSQLCMD $cmdGetSQLSchema
    $TonexTblSchemas
    foreach($TonexTblSchema in $TonexTblSchemas){
        Execute-SQL -sDatabasePath $sNewDatabase -sSQLCMD $TonexTblSchema.sql
    }

    #$cmdGetBlackAngus = 'select * from ToneModels where GUID="aa5220d2-c8c0-93bc-659a-bbde7d88691d"'
$cmdBlackAngus =@'
INSERT INTO "ToneModels" ("GUID", "Version", "Target", "TargetOrder", "TierEncrypt", "Tier", "IKGeneratedEncrypt", "IKGenerated", "Skin", "Instrument", "Copyright", "Model", "CabModel", "Tag_ModelName", "Tag_UserName", "Tag_Date", "Tag_Keywords", "Tag_Description", "Tag_ModelCategory", "Tag_AmpName", "Tag_StompName", "Tag_AmpChannel", "Tag_ModelComment", "Tag_CabCategory", "Tag_CabName", "Tag_CabMic1", "Tag_CabMic2", "Tag_Outboard", "Tag_CabModelComment", "DateAdded", "Favorite", "VisibleInCS", "VisibleInCSEncrypt", "Factory") VALUES ('aa5220d2-c8c0-93bc-659a-bbde7d88691d', '1', '3', '0 - AmpAndCab', '80.LBvEJQtIFC6c9FCd+CSvh6bdKJrXm9ISJVvA0bvawvTUBGZxF4os6MQKNqT7rCqBemy1AxDQsh85sxlcuYhzp3c77DC2GCFOol.rvCLO89C', '0', '80.LBvEJQtIFC6c9FCd+CSvh6bdKJrXm9ISJVvA0bvawvzeH314qWS9vnrB3MYYBQSXPSeiCy9HZ45S7lZvqke.PWZscLZ5OapMAAkPXvogGr.', '1', 'JCM', '0', '', '5200.zzW0DHZ5DHdX+LVJbTzPQZKMYsRBqFKUZbVnU7nYjRpvkneYfgSMWs5ZUZCvG4x8e4bRWrffgQYeLGanD6tMxqdvvqGtohl1h2Sk4r8NgYw7xmDzj4xO6oYqR33J9+Qw6AIWgZ+Di.2rG9.V1PGYpMxs6Z6eE.okEkAZC5BMeugOxWaJhayGlcKedkRoLh1JvP7neiGTPxvD5256HVuzSsy8tDmuUD2vw6N06K.ZaebolWL5vrqQ1WWFhFzVSIXsH9fn1Kugx2TSQsFR7ArSi8qhXAnwsiM6ZihQ+Et7dRbDuOHgKUzojDdPR7BWRqo04hABSedpHDkuefBeUz0XpnQCnVnPUVh69nNjexrIUUlFc2CugRA7UeYRVbGbySlpc1edSiBKj1Zd17UQM2yCYP0GNrmWfGAh4n3mzxBY37RjvZjteteVVMjKJEqHzj1u2zjJSxkkgspQeCyF.gaXtTgeVvbYB+PpHlyOBSIMp24fxYHZnFDsFsNAGCh7M7Hjkf5fBr3ui213YAKcgyQWrlgLp9yqj3NrM9BqaTrvfNkRc9J4h88NqwxQKxcQWHwmj8ainUusPfQKOlvX2ANhCegFDLnxtS10QbkFq6pantNGWyqrZHEf8R8tR8zU7ph5JfBjkgYTH+PScAdyK5mNDB987ej7FC159ZBFpktyUEb.EeKBE0gy.lh8fD+RWdGFPUuLkFMlbNxwdQEbvctU+mnhdKQnkNdQic8XNyfXptPlK02htIM7tWNThqyBu34MX6Bz.9YjpWEkR86Uucf6j2NsPK5rzlOZSIGfcy9E7AntrWiJEOcnatwa1rueq5wW8oPYfx8kPOOpPKjOns7QxCCxl5m8T5FXfjcid8Y9m5NA5HLdOl9Z3JnItmcvQcbEenbOMOBvcjHZGoljRp+WqCgovOcCU3C2AdXYsm6U5W33LA5XksySOV4hfTH1.sWWjKgufB1FuY3IeXctFP6V8GnpJV+N1Pdw2bEhVJvE0SfcIQZzLTM116lkCDnq6DPoWaWThv6RvEdB0wZePWGLHrTNWl6ii+yJQFCqvKIanHWDWZnDUGN0XmwhPQKIkeXPC4mwS.U4GGadKhJXSepxtyDlz+Rk0y3w3bG3I3WbED1m47OhLB.i+Kdar9fiuK7wCRRCzISmrgMPn9Sg2raDisCK+cikWw9yEnx1ZDZrcvonySFxieUz.fntEOSTEA9fnyUVmcvYlI38MsHFnPrenFHC7gMEhYTJ1JhBKUwmfT3ji0zw5JOej0mwygLTqRxHqGowxnPInohPfGvvo8RhzNp1ztP8OTQb5xoPqMPV59PEBJLuIePo5J6lmvuZAvI9Sy5Hq8pv3o6nyOJHFLjMImNSRfRGKlE4Jzg5Hmm1JMZcGb2hqsjNWpT7shlHln31m8vklVSnQljSYGf+cyhOA9XVSSRzZkvFpSUxxrYIwhr3AzZ+2.DJ3+gjgFdZagEJ8QQkyPN5z42zaGFgg0En+J7OG4Vv2nbSB01ldkBCP1Ty.EmF3lzP+H8WF20JP611gm.22G7vgggPps09KsYT7ncbiUUmUogpSePHcYom+P9qWUsapKHeIGEgVs+DjIL9S2PJ6nH0pUHYCNh5qNGwOJb.nxkV1sTi2tOAPeNmeVDVZ7gpBW.AbKIlAPgc4eS2ffPrYqwGgiI6lYuMyLCMDsoNSVWGchllg7xwdYoevHD+.ZvbuLFq+GfIGeFztLsbAHWO6BeBB7wK+.MSCihAxYi30uY1F7cvFDX3W4kOVCXw8IoyM1gO22J5oCe8bHvFdNkQaY7U96fb3WK3XXoz4RLhxdRh28NPDYXxR0Udi6JPUjq8+zMkMZrvUCCGcbuzWJOV8W2PpCUaRra.AJYicT+oTLSW88KGRYSlzWmd5YF.G4IBcG.2zIdeSjM7usEYupSwiGvieIki69DBkeATPjKbC2A6GXU3i5Thg5sP9Kz6Wu7KaKscBjmdsRqAju6IXzyyrlWH1PI8mXtuOGV9YN2Kxy6nzTh3nDkUhzYazgnRLecKhWMSZwHdUURNOFAxspNVIIJA.V1kR+lYAOzkJHONljKfiHaUOkcm4rTDgDcNUTLKv+MUxLXcC.GpJlqcMKooC.3vUwHnQkeF2hivEFQmQScYBik0hIzLyWiCOk2525j+ul.Mw6nHBjZ6QcHnzcYf5e5lzT7ZmJ9Iv4698uZ6RFEB5dB20DZR8xRn3fVdU0ekRWIE1YhovBG4jgn3yshilsDVj3Oa99t0yU6ZXQd1W76einmHptXiR.+Syn7Lv5wbMq8untzTqTrxis+nuPk5I7JnMQ.cbLQzZfg52ChRzhlZtW8N3qSryy2YL2b1IN7CsLZs1G3JJq4M85IS.SycJuYZfa+EcjMyCczGONUq+qRAeCczjB7R8IVT726UJNIj2LuUWraUiKNPRsaQpXWJB.PjMo+8MHjMfGJYPKryyTGWy+aBps1pw0JMwVLT45NAafMBFdVl2qcf2.l65MrOkrv9G8OLQmM5.65Zzik8LzsJiKggsDtbQIRjiHhDMtWvJ1dFd7TPou9JFOb00AKDWelbffgty9xHg8zQoNUFkX5iDoiYQ6GT.4Pd1WxYmNgcLQEEyHihcljp8XLgKfuFLVnRQQRJ0167LjFyvQQnMwsk2KWU4KE0rWIbKFK13cEtRjKkoaGi2NmxbtoW8tt9LGtW0c3+Lv2iRZ6sKn72ZPHdrfIlHiw5Xci2s.Ez8qLPRghQHc5k5wPbzYUYfcNBKqHLLTtAFkJZ7K9ZFbDZbEQj7FHnDjWf.qmLRTyCEZbpnz9UCo7LRH.ruZVgpunXXfjSeUwNAEhtqyuAy6FBxcN1TkYqp9qy7Q.uHnmUw9atQ.NKTyU72n.trO3xPu0syd2v74ft8e20xqBzI3ntlIjgh452Wv+ZSzmvHOHxztSe.hzajEA0YFrtFlmrdwrXly2o3ix80ywbp8yMW6RHnEr+9Bds+dyKJYWORMx1BAGpfo.NVEYAHuSOTD7poMjgvgBdDrYe6y8U2xdGyDggDQ5ecVHTzmI+42L1EPdsFTIsI7jI6IOdupkZ36pSg0Uz7BWjL+rmRPlvNxVS1go9BhoLkWOjWxkQBaMp91PjzqvjWDZUpuAIBUOws9gVcqIXlZ9mZROsauz5AXHhcTZV0x7phuz78KbKaXwi0cAiGLMMTZ9ptEqwTs3VTRnMZ.RYdU94NxQQ56jsP1JXwrwvUShEJb06uAAnTGogp0FkGHPCckAGOVVVA28wFKQwHZAj0Ex.W3l+aCLx0aT0SYFOohLqs2qMTk2tHXK7pwMrFhWG.WIB9NSaOamY2wti0IYlR8TX+KqJf1un42ZpV.65CP966IMsVglRUxQ40W56NQvGfN1bVUM4JTCwo0fRWGY3fNNXsz6hkvSpv4jk2H+L1dWBQ23C1UcRkh+wAmNjc.0LW6Af8W52i9eF6pc2qU2rxTuqWkpeTuKfQcEMpBQJxzjyHCDj3Pv1xNRk5zvWcISLg8IHReU0nkxIiXbZ7+Z1Qk5bKqSHkZxIejXABfFHIANw1gnJCXKvwmIZNk4nXhxPyIJ.+grB2nFdx+yj3q8MUpoBFutuN0HDZgwqTdjKUJM7zfVt9VzaBZwB7KhbmyghXUcKMB.3VpVih3S9gbTi+HXPqU6o4NR6QZbURdeA+iMWtO95E7k0bQhqs2DdOpHxxC77nqlL+.g.Uupsk0wBHdbIou02YznmN59VyjT4DhHxRmqsRhHZ+Gs2+.2jCo2CRtDqUg121ASAN0qOyYypr43fUNR1lkKrfTASREmCxB7VP2bzmbkrFsiKPEpceLNkvBMszAEy5ueHKBtaTw7NcUNmA+4Ik6cvpDT.qKIo5T9M7.C94mpIhI8k+nXGM629mL+PcuAC.kR5irKedtOCi6TU2vh73vYFAY6P6KiqgIUQvO3Mw8uZamZ5Re1JZ7RI09Dlj7xhm6YX5il8gZcpdGI1C3cRvP8wxHhRWoy0oUfQjP1QQSFCGV00fDZ+dF8M44J94hW.g5RdPIVVpIF0L+J8i4hgvUwwIarKk5UkovAg506Akz30PgV7w1dvwDPF75+2ouEDn5vBg5EEWiMj3C2rDCRd2r5VKLxCRKQwi47gSW6BUR7.B2BuolFPsgRnU6dBShSw5xhlvOZ3Kkp7zGMvYP+v2JK8so+HEJyJJ2e7B3ZtE9GzmUagQj18E18ns21d4qVMDnYtNhkZk7o11nYkprhiB+TOa1BXTENXgtWGN9QwsqaUVd9B5+qGuKQkpZ.GgsTs1iMU1zL4Go9lxQfO1k.HDcWaZqiVLi5u3RLmsB170h5cHv6lhM3nnygPdeWMfU3TZ7blvqQyxHI9pBPogOinzF+S7qqc5tSiNScqeqe6c1KBiDK8kOjltJsPj+8BdV+MPVftRAH+Ub5rRXsuBMpeWpXrZozHAzaczxHGgtoSmEqVYRaLXo5.v0ZfipzDMRZ3RIMlySDEzvwHAqB913OTQY925rH0SdXcwbp9kI0Tfa4yZPUe+1SpIM23AnPMTpFGXSphDMb6Vycj.dHp3B5s5ywoOQyEVybHceVInTTVR10hAPIJugVSLHatRy+cC+0E1dwP5OFtu2WZc7ivTvXAh7yy9ZWrSf1j40DlboLuj2EdpAVlCp.Gy3wiVVacsPvX8zCP.lYqVng0zR+j1R4rlQDTux3cVkPI1aabBAhfn5w.V.2bvuty9jzqAQRIlu0CsmwzPkE7SC1p.kpGpfOWYKu7mDINPJ9i67Czbu7dq5St1QxkwyRiQqz9NneDiLlwkAYspnRi7aONhT3JzoFSjuLctbgiVs7yjAS4mDrDIfz2YRj1Tz+iriGNlmM9MxJy233IaVerpl1HLzrTa1EBYft+0j.g3I+XPiDtXMqdFWkV31a5P33YY4Nwg40pO8wbks3.QcgLJdMdWN4Ds3VWOyrJC5+dgejPrfTaxjJOkEuOQg1A3m6CdyY4J2xKZA4upXd1xvRb1g3B8X9HIt2X5VGWSB.1bQ2U52t+uGdYwbMwnokfdkwlb7yQiVEr9jF89mLdxHrmiFlnuMFpxchCR8kWE8hsjWfxud6W+YI7Ye0q2w.Y6Pk3moUSvpmCoVlgTXnTWS9ExlhzE4fTBYPfW1zu9SIjI06uFA5rnywfC7ippKzjN08OVAGZvx7iDFURm0TCzqd2Mqey0q4ww6J.W3lWZZ.Fm4yKbTaQEq+VlrAROC2Nwe3PKFPmhVfHP6AvYZMvPD9uXmiyuoeLuhERrkyAe6E3bvJvQnwGqm6Xo6b0NcqfD0RqV9WMer7KXPq7HEvHZQASRSN8RcBZ.qChHhsWv+BYxQT6lFXZU83JO3Cz0Gx6aDk0XytN6sJIUSVee71M0yGZWi9NurLYlfHXHCnGkMKE2VM7ZrdMQSvZVrCV1L4liOhrnR1y4zg3F2iHmhEMv1.tMiKQL5UpbKSAt3m.EWf7vdPRl+FeqLbQzHGTUdp.xP72zQugU6I1CQb80CRbZzeWv4nebTHY1FupK0kH0Z33l313YJ3G1hrJSm4.vQxkSZDBG.+YY08WGRCpgFdakPP4xV6oQitPVto4RV90MhAgdsZjmsiKCEvDmlPdqWsTQ8LSg+sMcA5JhKNpCXaMW2pfpy2OXcqUvTMu3WVoWoGfvRBR2XsB0Ggkj5NWIXl.h7IiPuAWJW1pxerV15NSfLpjFkmikOy0aJIwsMAsIETvDGKQilPv6dFdMvZ2LEY6ut8APOBoz8W5lgZykjDP9iHxwjrbvQ3ZxTm7PsHAKEa1mbGfz+74cje8sPaMq35jdrTARpTnVPCLPBN.02PdJbTRWY4l2OqTTd.R0Yc5pe5Fp5IvgiVXWR6JZxmb0bjQObCwQd1nQi77ieCsky0t3ZeM1n18qsfGmeXwyB9t9P.eot3HZUa2A4HBjV+bFgHvvIaBWAFD4J4v0Mb+1kBHL8vRsH0g3n7XDQkx.iTdSPzGnNEey9GkdF.jynqYg6oDt9il.VHyL7..k9D2BB1ny.fvRIbAVm.2YFOP09grJcnQPum499wAp5uOKV5lDjZDAJmXoACog17dHDoS1.xYNpgB0Mx91ccisR4Qm1v3X3f8H02jJ8WoHGDoj8OtIyoPeALr1zKY8wHMrAWlS6flhHihS.tN3JUNA4Y2RM2hQKC4ZL2T.gWRZtvcdeypYK8TcHB8dH9iI+t33X1G4VAJHgESVg1VwVGAZqZKYWxyAinpB54tgKUFCKBjH00KFSGlekIg+1xpUOIxiIcHR0UKO.NUHTmPARlI3ztVg2gZiK593lfsEO4ICWInGo7FO50uPqjurfUlQ9xQgdqzSWG7bQbsbLlQNhOjRoFEt+oixv3OuBHEUrAJoM8XYKGgRfQifQmIPJU.tXm3+qWmh79Xxy+DPYNwMkrwMJMzR+XLD0qc5wGgepecHkQBJ25E7m7EGauKq0uFQDX1Xd4sT80YhdzK.+dD2hDkP.NCB7mBX7wQQAt+liarRYdiFrd1e1w9Q6QEk4aS1VzYs7AQP2ZZ0tXxU1JbQwHImevloRk56OwP.zV8gu24.CD19203fndowWgw5WoYI4PBlFnkIkojMV77oFKwsr0RaYegkrS1am7R79NjZIKMPukoIS7aRe5Tq42oyLWjXs9WTzW8jjkvIuaIL7ThB3imam+p7Cw7LL80LAvpsKh9vfhQd3WJDX1KXbPVbb5UFFboUXBtObU1l4Aau0mWWY7Dgo2sUa2J8aK.onu+DIIPukLHrMxay7313wvRDVz.nHAeO9N4TQxqkvNOnhpzZpaWmxE8KvkOUNqcqnEnkrpdwcvgRJjmadLxB4SA2KMkn0Dx8X9biYvTrCF53rf4M+r2IM8h7czcAt7jhKplJNN9cbRrb1xK1UVEDMq3.siDIFNM4nH5nKErKyFY9MDXvbjfY335opoSGHsaIA', '8200.vrusdhbfeGN4OXm2Rb0ggAi+kg+LXnL3IHTf3GxFJ8cSBuPoFuU41QJYAZZ+s408kxLAab2reNqW03l9vC1Xt.8S01VuTRiPW1prCv5StmE+1E+tg+Ed7OXwSJkSXUEq0VS1ac.ktj.rgwEzBAwlCs7ke4nBgFoUxewEkWdBUdTcjpsAEGPbijSA34owAVoqdWS0Qd1.CmpMzuds31mES8totCWbQ7zr.m5YaQ9crFx42jO.ue.Z7rCBCSDYeu5qdkCyi+vdZLXztdkBkEKspK9n3NHnGJtLIhSAjftn5geehrbY32xuk4FjF+s5e+nlbWU1ePiHS9fBgcN5cH3cFoapVEuAj4YF+k95ow336GjUgE+dowuDj5BfE+cxWqo1pa2c5j2elBnvHQKYTgIgusjkweKqhjMonzoYe.UF7QnY4yw49E1+BJ+MYXdNbbMhNKzDu09Z3WklBaH5t7Qgr2CHo1dpTL.+M01IQDoeTDmsxjexHLq7VNFRObpE.y37ydVmcumB2Lro5OEJ2UtwxhTxge+ljnnBpjdDULneXDAuLi49d0ZOKuvEJo0Kry+JCQeUBgO9WXL194+s5jwDDbI+gLUYlDHDmS3Va8WaL4XlztYDMFtPrxJjZq0wBDfTnzhn4TIr1lqJzZnnLZasG.t9tJ+gmCprez2NX8zjNNf35PByBYobyZ8kzMYLEcs+F+wNaZJDLy4q6+clEM1UuMzBovHuX0k6Dp3MhsC1D5OwdTZR5zcZP+HzKF2pGoTFwNOEKKtfn35jiKIa7vOy+BspE8+GtCGKa0g++JxrP5W+sGT2nOZ.H6tf4JF5dPzJaB8FWtn4GTLkVcUGTvk3ogiIZK5MbXobqxiy6KoL0VnTJ3bR0xq4fMn0zEgOCVWTDPrtf58HpZaZfX9liYG8Xt8KeDaruf.B7fDPWkVXv7BXGM76EdZcjvfJzQxIoNGy6Em2vpt5MFFHt8R.PB7t2XkY1YDvkQRDa5VLq4+f2Z+wjJSJKZRHDG.naGLToshL.tpjbnABr6IH5vJKRLt6xAxy06BuH0bcEltCNByDGzHq0DA4uPEnYqKzV8WxQCVuFdRSzrpsf3jxpnSYJv1tT2x8bKR+IBn0aeJs.tbTO3cxh+j8RtS8ZI8JjMCawPF7cmSLxfeVEhkjN4DZYP9VLh.rxSJpq5Y9A1UDm2AYIAqcKpPwAtc7+zQz+B8DygNfK1v1z7lBpOMdwDlv.Kaebp0m91DL.vOsTCelJeMsjOO89grc9eVoy1nnX4w.Vb3cNZi3m7QZ+PhKssv.IlUxpgpRsU9qBL8j1gSTMDIAti3AegFlOiKBv4S4eiz7JQEEO2G64dDyeM9708aOi5Je21qnw1QB7is9wWX8p7FvThiAW5F9RufkO.ndhfR8gRkAdhRfDxhH29+75TkdoUyELEJSy7LSLqe+Qef+6ImOQXxO6QO8aVcv8X8BkAZh3.ECu6PNzIg+dXTNiJi78.A1eNVJ9Z8vFa1dezLOIBWSTO4MRnCQdY+EIILCArm.CLKddCS1dKec6gp0GjFTTBbq76j4ll8i0wZhy8z4mUKRQXwmx.W8Gu357neQi3DTNKtCjBlL5PS5vlFz1oi1Jaw9IAK1zZ.HiY+lAPkHgisyXVEm9i7W6B4R.39dwb3NpvjWFcMlUA.mGfQ+1YlsFZkw2.tbRuoKbxG3yXw6VJAqftjj8D.ByUaLL+7itIveZKa1PVthz4GAsORz6.HXhGASW1+O02CbiEfkQ08i7GT.tw3oO3CgeyZen92goxBJcD8JYbXvie7vJreo.gvI4wLlZEL0dgvvHhqwjp4jWAcZG4u00SiBC1puR.iyD9FOmjrrku1Br+.PlPEXWuFkAK..6rT6zUchQ1Q4S4DLMbBqp3O0tF4F2LpZFrmcM3Ts73Qkw.6FoYeVePT96UKuKroSWwxJS.3y9zuEBPoo2eSk.0PYnlHOx+3.cuaKS.UsHCi.pAj6FJXESVjrpHAMY7cC0O9B3Na7zoVYaRyDl.iFGfeCJcklwIWdJRhBVtOvuezrCwFLQt4DueaTk7PWoxzX0rwsOrN2LQNjccb+TKlbeOP7UIdCI.6d8tACfIHLi5GGShOfhfYi3NNo6DfwQgeMe3a5vcUo3aYRiNwHN.pctV7vgMwB1HMWUk53AASkXJN1kia6WF+Mhjv0GUWDLYDdBwVKTcOjZlJ8pO3AnqFqVTltHDm9mYHNVaKnL6draWOqAeejNhWgqXIrZloLmSkiCwMu7XJoTnaV1u2v10poWu+TlhMQfI2PpalHJ.qTSZMdEfyoYJuhwqog1Xtb8si7RHs4mRbyBjshA0g8pwqQ6XKr4xB9jE1U4+8RavkoNY3wZ3tq9b05omgXmCeXX5uKfPSc6juqGKhakI0flYSWftEaTjyTK0POlLkUxXrF4cjT7fUZ8r755Tu8qM12ML9831hELsZX7F+oFRiTb2zb.RfzC5Xl+5mirwNFJTkCC72fjTD0PNDdol10B6zFEpdGyAUgVfB+GJIm1LmWTLVeSBH8fIFOcWjG8STEWNYUtK30GqdH6X6QmtAgXVZpZT6n+6jaBKnMgmF.J466U7jxZ5u06lRtoxuC4sb4iz.6r3UOkF.iBF5Mj8YID4RlBHl9QyMS0lgtxfdD7A4XEFZbW1oI9YltQeOSqe7hZ4HjucVTTucG+o0Zzr2.KDH7XYeI53jRb8OZ.hpVjbCnYpZeUC+.VM8Ski96SzbxB5Ummw7DvbjKPHp9.cBDQqnzIL0.otE9afSKnIXdWvoRQthNPoz415c7iBEY4nl2745XDoAywIC9L7npAdq+Ds16+H9QoxJJcfwKXus2LeE4G9qKYrgsLlYL91KYUoLCo9+t8+Hp6pzUGOSy7AOfcAjLiLODLw6JG+IHMzW4Y0rBe.tVN1V+0w4ypQiLbuFUq1ZQuLcp7SQVKVJxvymNqDjqk47ixIVEXoa7R+eFFLlZ6X3+QeLJ3YPNbAXgb+t65CulT2ZISSrFDzvF69HPr6jAejfI+gWjIU8HPB+Tt+yjaQoarAE8oOwTyol0flcJf74enB5LUhdfv0gT2Bgx0XTfxLQ03SDyZhtSSldJq..Qbkw14qM7xFL+8YuFraXeKwk0UBAVsFevUhzwPiz0BGTOceistkhAEjByRFFoTsPp7QuugApuyRUt00sAcpuD2fk5vBoVY9r9zBfnH76gtFJDtlj+DhT7QbsR8P5hvw7yzi1EiDVjuDKZgHNn1FiR7upI.HirXQGy.TArvIbmwu+hnhHSnDBul3Na0lZyG2xg654Yua3oeMFSX8ZHnKKQKx446qJ9+Nnd2nXL.jI+ge3aMh8fd9Uims38VCVe2+kOVBLiiMSynIXxTSrgxOMndexgYeO.4z8H3YTjoD0wNky5EdcAs+MwUcIOQML6wnMGztoGqcjISn.vUSu.ytwC6Wj8xprXLTBLV6vX..KfuD54NkPEt9KtM9v2K5Ib9+Pd4RXhA0FL2VfigdmlCu.QVUr7ts9yQrxlHfzZgt3rTAh2Y7dEpMSBJ07H45vUXS+eX9un5MYg.leubx6+7eeSFkcNNi3j93L2IQwynLt0ykN1vEL8ffvqW9ZLpA355ElmlvuhG6dqd1Sdf.+c6D0TeCmGBvA6mcruV6bLBIWGztOnqYKdPUt3OnDXPcpeUW7wTanpAxxc83hakfvugDUK0oqEATwaBIsecN2G6CWMq3n.je0qf1bXdMJrhgMQN4ZwCwQX55Nk7rV29qrGTMzO8gDzOyi.onD4D8WX1QmcGK3ubIyc3OPRn2OfgyNILt.8o5mptMUs4xZjRCsUSkLHzeAktQKd57gOBOPo6boing2r+GOLPADykDZZV+oOrhpAZSUe3IUM0NUkW7anfLKWrl440Scb7Jp0NTzfEIbdl82r+x6C9iFNEDvXf7uVmKp3vqen9nOMJXsM1AOq58K2XqDqq.+1.GMIwnvb1ztqD..EQ9gBmuY1K1cP99pOAEkv4KgsI4ZynTUnoxoWNNtiFG8INuAugMKJMWnfJmJS.NuSQ9mZBTwgwBYklSgLiwcIM0.7ZToC+lgnTGmJazNXjefBtKwT6RfG1VljBf7ZDfE0CSmSX.Ni9FjLDw9KbP+f0p3cf1XnQo6A.xRG2QWrE87oCcFZmkpIBEiFvq0Cl4WeJcRpcBjybBU9oIs8uqOiweFoUx9MReC4VH0kLbWlGh5yOpyb2wRU0tMEiIltwCvzfHg8.b118HHElrHty9xdmyskGfMWmnlE9cZmgz+4RzXdylmLuafBBO2tG0qYmD9ryM3C+zW4P0Lvry+lu6+gKxUwhyALnWh1h5plJQUEC06AryLXReYjOyOYhgoBq8GjimyzcVifuwTAbm5CEcIhZmV3Efb3uzmlNJcPsl0fBabTmJVIWazWTyaZEakLeVbWFNXCoBQ4wKBVL+ZZ4E4xZuQtlDdkQ7XAc.mOZ.gIgbWblQFV3gD+cTbf2HWSMnitltKcxDiclUCa9JdRxXKf+EqEk6+oI5XLnOEoRvMVmSK3h5vAog6.ukYLb17PZX2Fjp+OcS5u.PtCQ1uQ8EP4Z72+Bi2fHyS6yRjfk3D.fFMc5NZQkWIMeqE.3r2hnyWsIUvVVttsu5pX9SP4s+We.plnYOx46KF7T4bWPxFds5Sr6VdlAlvn8K+mdPuoPXP51ndpH+SPFkeXm1OQvK91fNX1vPxzGmpZK5aGjSNpHaSDKFtkl4Ix71g6c2L8286QrOKzjUhOJEb7CMSJw7n9eByEUDl24MtKqkTmjW8sm8rnhKKra1JL8Tt1AJG9jgyArg6R0I3Gf3i.tS8ZRm5w8qMfPszGWrtcppiIewPn.DyPf7hZYiqcbC2n6H+Bhlk+rYFsRu8uYBhlBm0GTtdn+WrQdU3XhtS+aEfCTqDibpQmRqERXxKrICpvkf0aSPl71nbkwPtFDg1QATbO8E7pVaU0h72dXM9m4e9cZoFcXTt6PDS7IEH.PICRUeJmXk+mpAWGjHpMFCjsRflCkqNMxQwrvkwqwu3wF+cwkUWDouO+GIUoR.36kQaXoz24ks.fd4A8AiQhUe+0jHEqIavhorvt4UFKi76fy2JQ17Hu0LP+cvUpwEgFVWv6Rcf0Ad+kxgKMz9ubFPnJ+SF+A3.aI45vqPXzTvG+P+JU0F71V8THKHHO.IXco5GOY1FgAy1JAnoFJLYKsb+GBBg9HnF03xyS9kFKxE46cDAc560pOtCffpLE+SDGz8.Raalgiy.S+nfhmS.3j.UJd4FWcqENnyooXmjKapSdHaBlcpDFxxVsquizlTGI8TuEC+gOyI2i1abaHLgNQqRd1BtFjBtgX34xGtHn3Fx9cBqCmBxbQ7Zz3JaxQEpc2pedSFADJmdBdx5XzpkdVT2y8thh4gh+XnrenbNzqbCfVkIvDwMm0wzeUO53yDXG2ei.e4tmrZMMe7D01OOOLrPc9uovLAKAS8LpMbMrZwZPMffUhwLk50Ixt5z2p+zWNzNXZTcYrnhBNvKsaxEKYwBSUWEznnsDA3FIBCEEsRBeTl7jmY+SHgaqjiktkdCaKlLR7TelIVabKva32CKWpobBF3ia3lCLxYHFYh.AFV1Pdjyp+iBrxUQ8pnoyfCvoNDAHGYv33.QFh+2IlZL43xUVgW8x3yJqOjdkNQn+tJrtbEg+5+ew2PCYy021nBj6vd..bbG+J7HoOPwYEyRHRDukASPCF4ALdUhsn1S+dl7a.NavP4WCqgG94lZF0sol9dMVKdydZdq+HArMJJ5qYonpFV0QK+VODuAF8N2gFPseSPLg7pATClHidJhi2LGTyMOHFCM2ia5Ymbu3P0fDOQgFJX03FGGd+oMsH3EaTVkcBnir5bVxZbTpniWytw6AS.2Y0h7WMc4pgavnvXoe5n.SnFEP8CsehjsG7qy0p++ZZ8fF+BJ5jhS3cAkSVsNHjv4nLtLdHyS7MLMjVHx3b7bq3JAc9yuhgscscJI6WXwrTUCD5+UrNXT6dsXaez9U7W.dk9G5Nv7+KijT7K2w18ReYoQlm2Y.BJN2mHRBaRUFEzsJlx9GmZc10G98WG2Uuhl3H1wzM..sDJlAOcUZiIfWa7wpTkUSWhAV0kUe3JH8sgjE9V3+w3tpd+f5CeYdRYfF3.7eZzzUoK0vAzB0QofzondU06PB2x1rVgVuNd7bXvGzFNdWy7dTV47FU2dVJq+83pa7NmgfkCUANQSeuVFUDT7ugNNVqSUi8996hVk4inr2G.mipGX6bEpc59JIIYp1AsDo20HGn6c9btgND0veI9q5ybhVfSX.4bZvbrcgNgWZXN6uwNmrE8GiLcWYKZVYKMsDTdYGFVwzH1VMFG1829VC2LDKfkZcw7pobDuUIdemh7IR6eV.2muGv3Msf.EC0esiRjK9C6d4G5KPNWx89C00rP7mGhvaK7smHlhR79cTKdWW+duJSARkqVDHSuaAT0JOOrz94CTy31wznWL8X8iuBkgnr5aFjlv2sxseZBNKc0WSpclRHeG8PPlHQ+vUksRtWfQKhsytjYVYdH4L8LagtXIAdU+7apeZuCng9o4lJYqNOkYpcmMBVhx3uB+jeCfADJYxrdTb1Zo114..fQoutFeTJO9+C7GifUBZe0BZnXhKY41frYe3bA+SpIfwpa0nRwLjAE4XVeRRvcD.XkQlRDz+6OzJ6z9ltI.Y8LSqnkpqObgOzR0GrNgRA8paa67mqle+kPocspcgd9bRPW5kpG5KIfZ0oBNunrkVSpclkEpvALxe00u1V5elPZvREKZjDjISJud1tPhA1mLxmP1QYWUJZSTNN6hjVgky50ZqbqPtVdYdwff5MU0fkdPP4Z.9OHg3qCAbm0y7qHOfFDOP+dLYPsd1auJvGr.jn8P4TIlKVmPsfoo+a1Zxah4m.PpFa3i5nQHAluVVOUFhkj2xYVQELjai3e8V9hsLUpbbF04XrGNVJtE4+6zbJUAgRx+il7pfGtTBcItBnNS9nxVEkKwKUDS9POihzB2YhpkU7i8HTKCOzkT2hrxkOjHdF+mkbidZoOLQe8Ba3ZXzgT7U3J7hpnFizGejcQwYjpBW4raWcb3Fc0v46A2NuNmx0ZHKqEw+vlQt51J7jvm8DueBA3LZDyNKrCe+U056QLjQkOOnUj1NrQ3GiV6CDPg.fGRaMlJ+KYF4rMZ54byDgebenfP+cmzm77uaheqnroYdWfm+JkVkapT8iIVnY0KgIoprtIQVy5Qtx8xLwFAFzWAKWj7ZV7l3kZWlEBFzWJVrwjbEnuGwuSyGCjLFgd0HO9nDLomnNnd+VI1ulKZKIbDoowC0dsGkZALtmrzB1z4RYwPCYgjZjFbXw1klGHYcW4oT0qvVS215Y6+bUDh937V.Hu5YaCGTUufbtYXvYU0sQdZej08ibGzZTMe3oCfOhx7yyJDKgJZr0rHXARI5LEMy.hCq.63HgK55wu6EXKDlKkvOcIGJxNcOVZHfUBRAV6O6y+Q8c698awbDthbn9fDB2optowuBU87fXN+HL61WGiy8UGC5H1IhvBcdnLdfIg1ERSRxKe3rlPBcKSHjNI6jC4QEmfvwHy1UKl8E099WKIL4QuuM1pYpTild3mx8yfdfB+s8JN14LEt9bWSF1eupIZT9S8LjnhqM93ltPqtIGH+17Hv6PX.08FYqeH+2PLmvdN1d4LNNVmZGFX3nabwrUp54PtS2y8LpzzhgTAOO8b.tRZcL2FpenhS4+6Vc2GviaQuGabSXJXSzdH6qaK.lNH40eF71yu+DVquQeGpaMkEojf8sXYQ397WEFflD7AORKd3sR4.OjWB4dSIquxTXfl.SK8Jd1YqSZCzJ0Ora.ghsQG.+xi6TiT5doFHfBEYNPx+602ff++2C1b4lnEglQp7e1n1IgSuIEfbSdO6GMmuIWg1n3x6iLm.h6xtdV3wNJ997nWduUQzwR3nC8LGJ+IRYFHYfpvkKRwvEATqvngE5QcLIjJDjd287vU6pHAAHdvChsuUk+6d9va6HuzRyBg1FTk5NLD+Fr7cTwcpg+lQZWkS8OaZPmnOZt4mVDbD0whNmRal7gIGCPZUA3iuERBp2hyIHxKl65AQMos7xpHkqUZaxWH9Qc4Nw.Xy+5lP1evaYojOxgDntmucQ5M4D1gWd0Oc9ItxiWilHmLjeLIyl6QCF9i1OJ9jPRj7XUKp8DbMe.h6wVpK7kPksyP4KxcKc+O5e22CeEZEHNZ0reJeCm0323i+RacGNO04m4uE.MGXo7UWcp9L6moQiVATAfY.KdqwCIpgAhE5ymEGJUyOzJazQQ59Ari1G0HLFOOlLCwjw4NlrcYdC7C0jN6+spxhm86PmrNVAe+vv8mB+4lNIiaIYmUyCk0.KhQVyE8FYeJUvtRDdgx1Dc1twih8309ZJ1S6S0UuGcPbuJQcXDVSLiMFFZGTmcLwBQwnTvK3p0r.r6mpd4RtRR2xjlBp0JArQH6h7gWg9WABMSPrq.wUGeRq4sFu5cRLxO1AUgXE7ycXPm8y3VVr1FophsjxjtH3Y9gU9ShT4JQC7vjofSHvdNFMQ90abtsgqU+Qptd9x6STmUjAqCVrX2EmQRlwaW.7fATzku25tJz+SXgKn2rdvy+03Nc6vSrEId7epXfzPvA6Q3g4PRZB7+7QOZkDRXCsxO6fwg4ZeR3GR7yHW.OqhwWnZiZU7yHhz2NyGgSkhqsDO9bfgzvVdeuQrlqV+P9hV1veQ+VMmyPvNs1Jmb67R6YwElfQKNut1GPpyfPCmI9AjiWn8TgKIPSkzUSN2go3IALtWLWPY78Bd+pPys9WJdH22QdnKW4JhUOCC6xRCNNy1C8EEIraLSUouqbikDBKidw3xMk3p+of4JODk9DAK9N1nnhgHwX8FUKCm9+y.roHiDq.KGBxK+Ou1ncpbUbRuHD3TcinOl2LlxJYy1DXYP0nJ+Bg+Q.2j+bmKLarh2JpNhZA0Cvm6xsQpkquPn7dy.fAAXmp.F1CmBcS8777ZcpGOvXlAj7kQY+oZyBdCsRonf2eMr0vc.dqVrNqQgePMyszqSv0aQK8ycJd6ywT5z4XyAEcPE5bOwi7KbtU6Z1mK.GRk2GzN1KQSaT18Smt.iz2LzNrgPaKyKWKEzJ0xUY7ZzFzo9Ilncp2iUfKfSwPh9nwFu4QPZ3TbSXCBuF+Jr3W41T+TiQDQQ3J8qm.WjlB0QvCUDU+hlC0UIggnVgmLiGRKbgbFHDkbZQ..PabbrIkujnbwwJXqAku6gSu6EouMqiahCinwgjy39vSxiY.V9sAB8AjcZhQ8.w8rLtJlMhEELt96jR.ttXF2GaYr+Un4oJJ0JwscfQsYEmFpVoqh5KYIz6rfmH9PwlsmNgoU8WFy9UrfnJX.s3HgnjYm+DCo42sbDit5x5M31XU+5SFXjXr.BWhZuEPR8UwVy4lTpZHEhlsYDvNOMdVE816h82PxYbUwJKt5PK4.3yfMiITIFrc8PEPiahe6Ohx7tTS52k+KiZAVHm8PJJQLsRdcsEGicDL34LjKIR+4Uw6qnHA30SGum.3TRdPopzvyIbg3b3XaRuIZ.PWYiabcNMak3hOGgT36vKoakVEFEfHIvyEnd2zPagMU1miGS1lf.+5h98R53IF4WMV2dH2tx9xsIJjCKo2Os9RIHyFHkx03zWo6MCIsPfjDIi0qzvhdOJislqjv1Ya9i2pQgIaZsXKGUlY3Oal6QKobDQPIdHow1jrlXS4Q.k520RbpbH3CaOHuGqV624RTrGUol1pf978e.w0Qwe49NnKtP4eD1yUwHidar0TAlE0tGIuEcibuXHTtn5PJgRP9fbvAXoDDNo5yPiUTqYBR+DTLmmp513EQek50pO97tI3JekJFrVQM6PmVq.qWn3m.fDapI7pvTml8ZvdMKOweWjKoYOSQqz1aA5+m97r0G85GlWpdGlt7TjYHO95qY.JhJKVivWeOfsmnN2+Kffkt4U20VfWCNtZptQDK9IX68aN5fXW3FaUhi59k79Hy26EozTHJGeV6vBLbwRPMuAPRGqhP2nX8ofVoE8quABDeUdd1rFWy7nZZ0rhIOUYF1ocxRPLV8R7PA.uWGQo0Rt5tDaOfT9wbxds4Pem9CbqKNyuXPaQlz28EFzx8mOHcmZAhCwx+iJR1y9+d63y3Uh6zYkwVf2vNGb7ZRkvcu7ikysWMrm4Z5kssX8TXsAbNGzNRIw2w8ndYEsrqCVzpxHgLj4Ykn7Z631ftETTz7DfKcknItKelF5kGjoBF0h+FVIoeMor+x6z2.XMfJtJJfQLpO6dbEkc.N6DueWe1YjfhKCHkbLEX.QM0+SyZ.VeyZNkv3WIY636vpxd4vC.BwKbAw.Jh96HMUznKdZdc+pT9Wa.kYYFmDnoNzKxROXYNeervRbtn71iJNrQo4r45O24Y+SGaKuh2mSdg.xeTDwqnBSCW74S028nOKVzcY90z9Azum.OSnOUao49JZiZSP5RD7xs8AbmiGdA7FeC6iqM70DNfbgNUK5hiVrmV1IMxHcNmIyHbGc6PNLePyEPXGQQBvwh6wKqTJnNg.HlsiF40RK+aPTCLghsvPyfiogTXm61bOp1qoRY2.tV5YwpnUHfaj+G8RQuu6GdWjGCl+XVf613q0qWQ0f3t4iBL8ggnQ6kQ8cMIcKrsEjV5wndnzwabvz59YRijlh4j0bwXT6FlMUNTx85aJJ559VH82.1hYRyQsVpAhX+FkWCkxZqkrk9jnaKAJjDt3peoI8uajtAnEqd.Y.q8kiQJynDIfLQW1oapGPKmFFdp6TlJyjKiTOZ2wbZGnulzHSpDn4b8G6kHzIl9+VLz94X8R2+MAXML1kZVorpM70vMx0TsrjixuN0Pr9kOKkJ7LCOv2miqI8HJUL+vbhCbPKv5.+krA2GzPIxWmRMxccaMVB', 'Black Angus', 'IK Multimedia', '2022-09-29', '', 'IK Multimedia Premium Tone Model', 'DRIVE', 'Marshall JCM 800', '', 'high', '', '4X12', 'Marshall 1960BV', 'SM57', 'U87', '', '', '2023-10-11', '0', '1', '', '1');
'@ 
    Execute-SQL -sDatabasePath $sNewDatabase -sSQLCMD $cmdBlackAngus
}

}

#Execute-SQL -sDatabasePath $newDB -sSQLCMD "DELETE FROM ToneModels WHERE "

if (-Not (Test-Path $newDB )){
  #  Create-NewDB -sDefaultDB $DefaultDB -sNewDatabase $newDB 
}


#   Execute-SQL -sDatabasePath $newDB -sSQLCMD $cmdBlackAngus
#Execute-SQLCopy -sInsertTable "ToneModels" -sNewDatabase $newDB  -sDefaultDB $DefaultDB -sSQLCMD 'select * from Tonemodels where TargetOrder="0 - AmpAndCab"'
#select * from ToneModels WHERE Tag_UserName = "IK Multimedia" 

$TargetOrder = Execute-SQLRead $DefaultDB "SELECT DISTINCT TargetOrder FROM ToneModels"
$Tag_ModelCategory = Execute-SQLRead $DefaultDB "SELECT DISTINCT Tag_ModelCategory FROM ToneModels"
$cmdSearch =@'
SELECT * FROM ToneModels WHERE Tag_AmpName like "%fender%" and Tag_StompName like "" and TAG_Cabname like "%%" and Tag_ModelCategory = "CLEAN"  and (TargetOrder="3 - Amp" or TargetOrder="0 - AmpAndCab")
'@
$cmdSearch =@'
SELECT * FROM ToneModels WHERE Tag_AmpName like "%fender%" and TAG_Cabname like "%%" and Tag_ModelCategory = "CLEAN"  and (TargetOrder="0 - AmpAndCab")
'@
$cmdSearch =@'
SELECT * FROM ToneModels WHERE Tag_AmpName like "%Soldano%" AND (TargetOrder="0 - AmpAndCab")
'@

Execute-SQLCopy -sInsertTable "ToneModels" -sNewDatabase $newDB  -sDefaultDB $allDB  -sSQLCMD $cmdSearch