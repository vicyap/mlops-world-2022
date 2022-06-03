# Theses worker types have slightly less cpu and memory than their respective instance type
# because of kubernetes overhead. For example, if we tried to provision an 8CPU/16G worker
# (which is like a c5a.2xlarge), we may actually get a c5a.4xlarge.

locals {
  head_type_name = "head"
  ray_pod_types = merge(
    local.head_type,
    local.cpu_worker_types_rendered,
    local.gpu_worker_types_rendered,
    local.disable_default_worker_type,
  )

  ################################################################################
  # Ray Head Type
  ################################################################################


  head_type = {
    "${local.head_type_name}" = {
      # setting CPU to  0 disables scheduling tasks on the head node
      CPU = 0
      # this is how much memory the head pod should have
      # larger clusters require more memory
      memory = "4G"

      nodeSelector = {
        "karpenter.sh/capacity-type" = "on-demand"
      }
    }
  }

  ################################################################################
  # Ray CPU Worker Types
  ################################################################################

  cpu_worker_types = [
    {
      minWorkers = 1
      maxWorkers = 100
      CPU        = 7
      memory     = "14G"
    },
    {
      minWorkers = 0
      maxWorkers = 10
      CPU        = 30
      memory     = "60G"
    },
    {
      minWorkers = 0
      maxWorkers = 1
      CPU        = 60
      memory     = "500G"
    },
  ]

  ################################################################################
  # Ray GPU Worker Types
  ################################################################################

  gpu_worker_types = [
    {
      minWorkers      = 0
      maxWorkers      = 1
      CPU             = 7
      memory          = "472G"
      GPU             = 8
      acceleratorType = "p2"
    },
  ]

  ################################################################################
  # Render CPU Worker Types
  ################################################################################

  cpu_worker_types_rendered = {
    for wkr in local.cpu_worker_types :
    "wkr-${wkr.CPU}cpu${wkr.memory}" => {
      minWorkers = wkr.minWorkers
      maxWorkers = wkr.maxWorkers
      CPU        = wkr.CPU
      memory     = wkr.memory
      nodeSelector = {
        "karpenter.sh/capacity-type" = "spot"
      }
    }
  }

  ################################################################################
  # Render GPU Worker Types
  ################################################################################

  gpu_worker_types_rendered = {
    for wkr in local.gpu_worker_types :
    "wkr-${wkr.acceleratorType}-${wkr.GPU}gpu" => {
      minWorkers = wkr.minWorkers
      maxWorkers = wkr.maxWorkers
      CPU        = wkr.CPU
      memory     = wkr.memory
      GPU        = wkr.GPU
      rayResources = {
        "accelerator_type:${wkr.acceleratorType}" : 1
      }
      nodeSelector = {
        "karpenter.sh/capcity-type" = "on-demand"
        "mydomain.com/gpu-type"     = wkr.acceleratorType
      }
      tolerations = [
        {
          key      = "nvidia.com/gpu"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
      ]
    }
  }

  ################################################################################
  # Disable Default Worker Type
  ################################################################################

  # the ray helm chart comes with a pre-defined worker type
  # this block this disables it by setting min/maxWorkers to 0
  disable_default_worker_type = {
    rayWorkerType = {
      minWorkers = 0
      maxWorkers = 0
    }
  }
}
