-- https://github.com/neovim/nvim-lspconfig
local lsp_config = require("lspconfig")
-- local navic = require("nvim-navic")

-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local getOpts = function(desc)
	return { noremap = true, silent = true, desc = desc }
end

vim.keymap.set("n", "E", vim.diagnostic.open_float, getOpts("Open Float"))
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, getOpts("Goto previous diagnostic"))
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, getOpts("Goto next diagnostic"))
vim.keymap.set("n", "<leader>rf", vim.lsp.buf.format, getOpts("Format File"))
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)  -- ??

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(_, bufnr)
	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	local bufopts = function(desc)
		return { noremap = true, silent = true, buffer = bufnr, desc = desc }
	end
	-- original
	-- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, getBufOpts("Jump to Declaration"))
	-- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, getBufOpts("Jump to Definition"))
	-- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, getBufOpts("Jump to Implementation"))
	-- vim.keymap.set('n', 'gr', vim.lsp.buf.references, getBufOpts("Jump to References"))
	vim.keymap.set("n", "H", vim.lsp.buf.signature_help, bufopts("Display Signature Help"))
	vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts("Display Hover Info"))
	vim.keymap.set("n", "T", vim.lsp.buf.type_definition, bufopts("Display Type Definition"))
	vim.keymap.set("n", "<leader>ra", vim.lsp.buf.code_action, bufopts("Code Action"))
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts("Rename"))
	-- idk what below commands do
	-- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
	-- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
	-- vim.keymap.set('n', '<space>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, bufopts)
	-- nvim-navic
	-- if client.server_capabilities.documentSymbolProvider then
	--   navic.attach(client, bufnr)
	-- end
end

-- cmp-nvim-lsp
local capabilities = require("cmp_nvim_lsp").default_capabilities()
-- ufo
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

local lsp_flags = {
	-- This is the default in Nvim 0.7+
	debounce_text_changes = 150,
}

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = {
	-- rust
	rust_analyzer = {
		settings = {
			["rust-analyzer"] = {
				imports = {
					granularity = {
						group = "module",
					},
					prefix = "self",
				},
				cargo = {
					buildScripts = {
						enable = true,
					},
				},
				procMacro = {
					enable = true,
				},
				checkOnSave = {
					command = "clippy",
				},
			},
		},
	},

	-- python
	pyright = {
		settings = {
			python = {
				analysis = {
					-- default values from lspconfig
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "workspace",
					-- custom value
					typeCheckingMode = "off", -- let mypy handle type checking
					diagnosticSeverityOverrides = {
						-- https://github.com/microsoft/pyright/blob/main/docs/configuration.md
						-- "error," "warning," "information," "true," "false," or "none"
						reportUndefinedVariable = "none",
					},
				},
			},
			pyright = {
				disableOrganizeImports = true,
			},
		},
		handlers = {
			["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
				-- filter Hints
				-- https://github.com/neovim/nvim-lspconfig/issues/726#issuecomment-1075539112
				-- https://github.com/neovim/neovim/issues/17757#issuecomment-1073266618
				local filtered_diags = {}
				for _, diag in pairs(result.diagnostics) do
					if diag.severity ~= vim.lsp.protocol.DiagnosticSeverity.Hint then
						table.insert(filtered_diags, diag)
					end
				end
				result.diagnostics = filtered_diags
				vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
			end,
			-- disable diagnostics for pyright type checker; let null-ls(mypy) handle them.
			-- ['textDocument/publishDiagnostics'] = function(...) end
		},
		commands = {
			OrganizeImports = {
				function()
					local params = {
						command = "pyright.organizeimports",
						arguments = { vim.uri_from_bufnr(0) },
					}
					vim.lsp.buf.execute_command(params)
				end,
				description = "Organize Imports",
			},
		},
	},

	-- typescript
	tsserver = {
		commands = {
			OrganizeImports = {
				function()
					local params = {
						command = "_typescript.organizeImports",
						arguments = { vim.api.nvim_buf_get_name(0) },
						title = "",
					}
					vim.lsp.buf.execute_command(params)
				end,
				description = "Organize Imports",
			},
		},
	},

	-- lua
	sumneko_lua = {
		command = { "lua-language-server" },
		settings = {
			Lua = {
				runtime = {
					-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
					version = "LuaJIT",
					-- path = runtime_path, -- Setup your lua path
				},
				diagnostics = {
					globals = { "vim" }, -- Get the language server to recognize the `vim` global
				},
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true), -- Make the server aware of Neovim runtime files
					checkThirdParty = false,
				},
				-- Do not send telemetry data containing a randomized but unique identifier
				telemetry = {
					enable = false,
				},
			},
		},
	},
	vimls = {},
	tailwindcss = {},
	--[[ jsonls = {}, ]]
	--[[ cssls = {}, ]]
}
for server, config in pairs(servers) do
	config.on_attach = on_attach
	config.capabilities = capabilities
	config.flags = lsp_flags
	lsp_config[server].setup(config)
end

--------------------------------------------------------------------------------
-- UI customization ------------------------------------------------------------
--------------------------------------------------------------------------------
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#borders
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "rounded"
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- TODO: auto diagnostic hover window
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#show-line-diagnostics-automatically-in-hover-window

-- gutter (sign column) symbols
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#change-diagnostic-symbols-in-the-sign-column-gutter
local signs = { Error = "??? ", Warn = "??? ", Hint = "??? ", Info = "??? " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- display the source of diagnostic
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#show-source-in-diagnostics
-- :h vim.diagnostic.config for all options
vim.diagnostic.config({
	virtual_text = false,
	-- virtual_text = {
	--   source = "always", -- Or "if_many"
	-- },
	float = {
		source = "always", -- Or "if_many"
	},
	-- TODO:
	-- format = function(diag) end
})

--------------------------------------------------------------------------------
-- DEBUG
-- vim.lsp.set_log_level("debug") -- set this then run :LspInfo
