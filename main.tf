

# Crea un grupo de recursos de Azure si no existe
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Crea el recurso de Azure Logic App
# Nota: La definición detallada del flujo de trabajo (workflow)
# para iniciar/detener la VM y enviar notificaciones
# generalmente se configura después de crear el recurso,
# ya sea en el portal de Azure o utilizando ARM templates/Bicep
# para flujos más complejos. Aquí se define un trigger de recurrencia básico.
resource "azurerm_logic_app_workflow" "vm_scheduler" {
    name                = var.logic_app_name
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    parameters = {}
    workflow_schema = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
    workflow_version = "1.0.0.0"
    
}

# Crea el recurso de Azure Communication Services
resource "azurerm_communication_service" "notification_service" {
  name                = var.communication_service_name
  resource_group_name = azurerm_resource_group.main.name
  data_location       = "United States" # Elige una ubicación de datos apropiada
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Crea una subred
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_public_ip" "main" {
  name                = "${var.vm_name}-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id # Asocia la IP pública
  }
}


resource "azurerm_windows_virtual_machine" "main" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_F2"
  admin_username      = "${var.admin_username}"
  admin_password      = "${var.admin_password}"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(<<-EOT
    try {
        import-module servermanager
        add-windowsfeature web-server -includeallsubfeature
        add-windowsfeature Web-Asp-Net45
        add-windowsfeature NET-Framework-Features
        New-Item -Path "C:\inetpub\wwwroot\" -Name "videos" -ItemType "directory"
        Set-Content -Path "C:\inetpub\wwwroot\videos\Default.html" -Value "This is the videos server"
    } catch {
        Write-Host "Error downloading or executing script: $($_.Exception.Message)"
        # Optionally, log the error to a file or Azure Monitor
    } finally {
        # Clean up the downloaded script (optional)
        # Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
    }
    EOT
    )
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  
}

resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = "${random_pet.prefix.id}-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}

resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.main.name
  }

  byte_length = 8
}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "random_pet" "prefix" {
  prefix = "prefix"
  length = 1
}

# Salidas (opcional)
output "logic_app_url" {
  description = "La URL de la Azure Logic App."
  value       = azurerm_logic_app_workflow.vm_scheduler.access_endpoint
}


output "communication_service_primary_connection_string" {
  description = "La cadena de conexión primaria para Azure Communication Services."
  value       = azurerm_communication_service.notification_service.primary_connection_string
  sensitive   = true # Marca esto como sensible para no mostrarlo en la salida de apply
}

output "virtual_machine_name" {
  description = "El nombre de la máquina virtual creada."
  value       = azurerm_windows_virtual_machine.main.name
}

output "virtual_machine_public_ip" {
  description = "La dirección IP pública de la máquina virtual."
  value       = azurerm_public_ip.main.ip_address
}