return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			svelte = { "eslint_d" },
			python = { "pylint" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				local names = lint._resolve_linter_by_ft(vim.bo.filetype)
				names = vim.list_extend({}, names)
				names = vim.list_extend(names, lint.linters_by_ft["_"] or {})

				local ctx = { filename = vim.api.nvim_buf_get_name(0) }
				ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")

				names = vim.tbl_filter(function(name)
					local linter = lint.linters[name]
					if not linter then
						return false
					end
					if linter.condition then
						return linter.condition(ctx)
					end
					-- Skip eslint_d if no config file is found
					if name == "eslint_d" or name == "eslint" then
						return vim.fs.find(
							{ ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs" },
							{ path = ctx.dirname, upward = true }
						)[1] ~= nil
					end
					return true
				end, names)

				if #names > 0 then
					lint.try_lint(names)
				end
			end,
		})

		vim.keymap.set("n", "<leader>!", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
