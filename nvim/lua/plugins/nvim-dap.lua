return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "jay-babu/mason-nvim-dap.nvim",
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    require("mason-nvim-dap").setup({
      ensure_installed = { "js-debug-adapter" },
      automatic_installation = true,
    })

    dapui.setup()

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end,
}
