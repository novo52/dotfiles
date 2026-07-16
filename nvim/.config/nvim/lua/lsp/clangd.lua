return {
  cmd = {
    'clangd',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--function-arg-placeholders=1',
    '--background-index',
    '--cross-file-rename',
    '--clang-tidy',
  },
}
