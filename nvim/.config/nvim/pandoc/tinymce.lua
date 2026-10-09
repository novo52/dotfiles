-- Pandoc filter for text taken out of a TinyMCE editor (Canvas's Rich Content Editor).
--
-- TinyMCE mirrors every href and src into a data-mce-* twin of the attribute and rebuilds
-- those twins whenever it loads a document, so they carry no information and only make the
-- Markdown harder to read. Pandoc's HTML reader drops the data- prefix, which is why the
-- pattern matches mce- rather than data-mce-.
local function strip(el)
  local keep = {}
  for k, v in pairs(el.attributes) do
    if not k:match('^mce%-') then
      keep[k] = v
    end
  end
  el.attributes = keep
  return el
end

return { { Link = strip, Image = strip, Span = strip, Div = strip } }
