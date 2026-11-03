local assert = require 'luassert'
local stub = require 'luassert.stub'
local load_fixture = require 'tests.load_fixture'
local tw = require 'treewalker'
local h = require 'tests.treewalker.helpers'

local default_opts = vim.deepcopy(tw.opts)

---@param fixture string
local function reset(fixture)
  load_fixture(fixture)
  tw.opts = vim.deepcopy(default_opts)
  tw.setup({ highlight = false, jumplist = false })
end

describe('Per-call options', function()
  before_each(function()
    reset('/lua.lua')
  end)

  it('selects on demand in each direction without changing setup options', function()
    local cases = {
      { 'move_up', 30, 1, 21, 1, 28, 3 },
      { 'move_down', 10, 1, 21, 1, 28, 3 },
      { 'move_in', 21, 1, 22, 3, 26, 5 },
      { 'move_out', 7, 3, 5, 1, 8, 1 },
    }
    for _, case in ipairs(cases) do
      vim.fn.cursor(case[2], case[3])
      assert.is_true(tw[case[1]]({ select = true }))
      h.assert_selected(case[4], case[5], case[6], case[7])
      vim.cmd('normal! \27')
      assert.is_false(tw.opts.select)
    end
  end)

  it('can disable configured selection for one call', function()
    tw.setup({ select = true })
    vim.fn.cursor(10, 1)
    tw.move_down({ select = false })
    assert.not_equal('v', vim.fn.mode())
    assert.is_true(tw.opts.select)
  end)

  it('uses per-call highlight and does not persist it', function()
    vim.fn.cursor(10, 1)
    tw.move_down({ highlight = true, highlight_group = 'DiffAdd' })
    local ns = vim.api.nvim_create_namespace('treewalker.nvim-movement-highlight')
    local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
    assert.equal('DiffAdd', marks[1][4].hl_group)
    assert.is_false(tw.opts.highlight)
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    tw.move_up()
    assert.equal(0, #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}))
  end)

  it('skips validation when no overrides are passed', function()
    local options = require 'treewalker.options'
    local validate = stub.new(options, 'validate_opts')
    validate.returns(true, {})
    vim.fn.cursor(10, 1)
    assert.is_true(tw.move_down())
    assert.stub(validate).was.called(0)
    tw.move_up({ select = false })
    assert.stub(validate).was.called(1)
    validate:revert()
  end)

  it('rejects invalid overrides without changing defaults or moving', function()
    local notify = stub.new(vim, 'notify')
    vim.fn.cursor(10, 1)
    ---@diagnostic disable-next-line: assign-type-mismatch
    assert.is_false(tw.move_down({ select = 'yes' }))
    h.assert_cursor_at(10, 1)
    assert.is_false(tw.opts.select)
    assert.stub(notify).was.called(1)
    notify:revert()
  end)

  it('uses the call notification override when the parser is missing', function()
    local parser = stub.new(vim.treesitter, 'get_parser')
    local notify = stub.new(vim, 'notify_once')
    parser.returns(nil)
    assert.is_false(tw.move_down({ notifications = false }))
    assert.stub(notify).was.called(0)
    assert.is_true(tw.opts.notifications)
    parser:revert()
    notify:revert()
  end)

  it('keeps command-style calls using setup options', function()
    tw.setup({ select = true })
    vim.fn.cursor(10, 1)
    vim.cmd('Treewalker Down')
    h.assert_selected(21, 1, 28, 3)
  end)
end)

describe('Per-call options in markdown', function()
  before_each(function()
    reset('/markdown.md')
  end)

  it('selects a section without changing the default', function()
    -- Markdown selection uses section bounds rather than just the heading node.
    local markdown = require 'treewalker.markdown.heading'
    local anchor = require 'treewalker.markdown.anchor'
    vim.fn.cursor(3, 1)
    local current = anchor.current(3)
    assert.is_not_nil(current)
    local target = anchor.find_down(current)
    assert.is_not_nil(target)
    local _, first, last = markdown.get_section_bounds(target.row)
    tw.move_down({ select = true })
    assert.equal('v', vim.fn.mode())
    assert.equal(first, vim.fn.getpos("'<")[2])
    assert.equal(last, vim.fn.getpos("'>")[2])
    assert.is_false(tw.opts.select)
  end)
end)

describe('Per-call jumplist options', function()
  before_each(function()
    reset('/lua.lua')
  end)

  it('uses per-call jumplist settings for movement', function()
    tw.setup({ jumplist = true })
    local commands = stub.new(vim, 'cmd')
    vim.fn.cursor(21, 1)
    tw.move_in()
    assert.is_true(#commands.calls > 0)
    commands:clear()
    vim.fn.cursor(21, 1)
    tw.move_in({ jumplist = false })
    commands:revert()
    assert.stub(commands).was.called(0)
    assert.is_true(tw.opts.jumplist)
  end)
end)
