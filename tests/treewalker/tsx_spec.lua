local load_fixture = require "tests.load_fixture"
local h = require "tests.treewalker.helpers"
local tw = require "treewalker"

describe("In a TSX file:", function()
  before_each(function()
    load_fixture("/tsx.tsx")
  end)

  h.ensure_has_parser("tsx")

  it("moves up from standalone JSX closing tags", function()
    vim.fn.cursor(35, 9) --         </div>
    tw.move_up()
    h.assert_cursor_at(32, 9)

    vim.fn.cursor(49, 15) --               </ul>
    tw.move_up()
    h.assert_cursor_at(43, 15)

    vim.fn.cursor(60, 5) --     </>
    tw.move_up()
    h.assert_cursor_at(30, 5)
  end)
end)
