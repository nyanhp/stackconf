Describe 'Lab test suite' {
    $webServer = if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        (Get-LabVM -Role WebServer).AzureConnectionInfo.Fqdn
        
    }
    else
    {
        (Get-LabVM -Role WebServer).FQDN
    }

    $port = if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
    {
        (Get-LabAzureLoadBalancedPort -DestinationPort 443 -ComputerName $webServer).Port
    }
    else
    {
        443
    }

    $apiBase = 'https://{0}:{1}/api' -f $webServer, $port

    Context 'Restaurants' {
        $targetUrl = '{0}/{1}' -f $apiBase, 'Restaurant'
        It ("Should reach $targetUrl" -f $apiBase, 'Restaurant') {
            { Invoke-RestMethod -Uri $targetUrl -Method Get -ErrorAction Stop -SkipCertificateCheck } | Should -Not -Throw
        }
        $createData = @{
            Name    = "Bob's Burgers"
            Cuisine = 'American'
        }

        $updateData = @{
            Name    = 'The Frying Dutchman'
            Cuisine = 'Seafood'
        }

        Context 'Create' {
            It 'Should be able to create a new restaurant' {
                { Invoke-RestMethod -SkipCertificateCheck -Uri $targetUrl -Method Post -Body ($createData | ConvertTo-Json) -ContentType application/json -ErrorAction Stop } | Should -Not -Throw
                $restaurants = Invoke-RestMethod -SkipCertificateCheck -Uri $targetUrl -Method Get -ErrorAction Stop
                ($restaurants | Select-Object -Last 1).Name | Should -Be $createData.Name
                ($restaurants | Select-Object -Last 1).Cuisine | Should -Be $createData.Cuisine
            }
        }

        Context 'Read' {        
            It 'Should be able to read all restaurants' {
                (Invoke-RestMethod -SkipCertificateCheck -Uri $targetUrl -Method Get -ErrorAction Stop).Count | Should -BeGreaterThan 1
            }

            It 'Should be able to read one specific restaurant' {
                (Invoke-RestMethod -SkipCertificateCheck -Uri "$targetUrl/1" -Method Get -ErrorAction Stop).Count | Should -BeExactly 1
            }
        }

        Context 'Update' {   
            It 'Should be able to update a restaurant' {
                { Invoke-RestMethod -SkipCertificateCheck -Uri "$targetUrl/1" -Method Put -Body ($updateData | ConvertTo-Json) -ContentType application/json -ErrorAction Stop } | Should -Not -Throw
                $restaurant = Invoke-RestMethod -SkipCertificateCheck -Uri "$targetUrl/1" -Method Get -ErrorAction Stop
                $restaurant.Name | Should -Be $updateData.Name
                $restaurant.Cuisine | Should -Be $updateData.Cuisine
            }
        }

        Context 'Delete' {
            It 'Should be able to delete a restaurant' {
                { Invoke-RestMethod -SkipCertificateCheck -Uri "$targetUrl/1" -Method Delete -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }
}