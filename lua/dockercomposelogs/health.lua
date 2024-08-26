local health = vim.health or require("health")

local M = {}

--- https://neovim.io/doc/user/health.html#:~:text=To%20add%20a%20new%20healthcheck,find%20and%20invoke%20the%20function.&text=All%20such%20health%20modules%20must,containing%20a%20check()%20function.
M.check = function()
	health.start("Checking...")
	if vim.fn.executable("docker") == 1 then
		--- It has been like 3 years since "docker compose" became a thing
		--- Not so sure if to check if the user has that or not but hey
		health.ok("Docker binary installed")
	else
		health.error("Docker binary does not exists. Please install docker")
	end
end

return M
