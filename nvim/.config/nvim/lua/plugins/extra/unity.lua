return {
  'apyra/nvim-unity-sync',
  event = { 'VeryLazy' },
  config = function()
    require('unity.plugin').setup()
  end,
}
