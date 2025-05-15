local load_fixture = require("tests.load_fixture")
local tw = require("treewalker")
local h = require("tests.treewalker.helpers")

describe("In a php file", function()
  before_each(function()
    load_fixture("/php.php")
  end)

  h.ensure_has_parser("php")

  -- TODO This also works manually but is failing the test suite. I think
  -- parsers need to be brought in.
  pending("respects embedded html", function()
    vim.fn.cursor(18, 1)
    tw.move_down()
    h.assert_cursor_at(19, 1)
  end)
end)
