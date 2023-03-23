local present, persistence = pcall(require, "persistence")
if not present then
   return
end

persistence.setup()
