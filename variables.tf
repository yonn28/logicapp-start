variable "resource_group_name" {
  description = "El nombre del grupo de recursos para crear los recursos."
  type        = string
  default     = "rg-vm-automation" # Puedes cambiar el nombre por defecto
}

variable "location" {
  description = "La región de Azure donde se crearán los recursos."
  type        = string
  default     = "East US" # Puedes cambiar la región por defecto
}

variable "logic_app_name" {
  description = "El nombre de la Azure Logic App."
  type        = string
  default     = "logicapp-vm-scheduler" # Puedes cambiar el nombre por defecto
}

variable "communication_service_name" {
  description = "El nombre del recurso de Azure Communication Services."
  type        = string
  default     = "comm-svc-vm-notify" # Puedes cambiar el nombre por defecto
}

variable "vm_name" {
  description = "El nombre de la máquina virtual de Azure."
  type        = string
  default     = "vm-automated" # Puedes cambiar el nombre por defecto
}

variable "vm_size" {
  description = "El tamaño de la máquina virtual (SKU)."
  type        = string
  default     = "Standard_B1s" # Puedes cambiar el tamaño por defecto
}

variable "admin_username" {
  description = "El nombre de usuario administrador para la VM."
  type        = string
  default     = "windowsAdmin" # Puedes cambiar el nombre de usuario por defecto
}

variable "admin_password" {
  description = "La contraseña del administrador para la VM."
  type        = string
  default = "P@ssw0rd123!" # Cambia esto por una contraseña segura
}

