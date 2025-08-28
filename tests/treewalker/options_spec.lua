local assert = require 'luassert'
local stub = require 'luassert.stub'
local tw = require 'treewalker'

describe("When given bad options", function()
  it("notifies the user of all wrong options", function()
    local notify_stub = stub.new(vim, "notify")

    tw.setup({
      ---@diagnostic disable-next-line: assign-type-mismatch
      highlight = "nope",
      ---@diagnostic disable-next-line: assign-type-mismatch
      highlight_duration = "one",
      ---@diagnostic disable-next-line: assign-type-mismatch
      highlight_group = 85,
      ---@diagnostic disable-next-line: assign-type-mismatch
      jumplist = {},
      ---@diagnostic disable-next-line: assign-type-mismatch
      notifications = "what",
    })

    assert.stub(notify_stub).was.called(1)
    local notify_msg = notify_stub.calls[1].refs[1]
    assert(notify_msg:find("highlight"))
    assert(notify_msg:find("highlight_duration"))
    assert(notify_msg:find("highlight_group"))
    assert(notify_msg:find("jumplist"))
    assert(notify_msg:find("notifications"))
  end)

  it("does not notify of correct options", function()
    local notify_stub = stub(vim, "notify")

    tw.setup({
      highlight_duration = 1,
      ---@diagnostic disable-next-line: assign-type-mismatch
      highlight = "bad",
      highlight_group = "ColorColumn",
      jumplist = true,
      notifications = true,
    })

    assert.stub(notify_stub).was.called(1)

    local notify_msg = notify_stub.calls[1].refs[1]
    local notify_level = notify_stub.calls[1].refs[2]

    assert.equal(vim.log.levels.ERROR, notify_level)

    assert(notify_msg:find("highlight"))
    assert.is_nil(notify_msg:find("highlight_duration"))
    assert.is_nil(notify_msg:find("highlight_group"))
    assert.is_nil(notify_msg:find("jumplist"))
  end)
end)

describe("When given all good options", function()
  it("does not notify the user at all when all are present", function()
    local notify_stub = stub(vim, "notify")
    local notify_once_stub = stub(vim, "notify_once")

    tw.setup({
      highlight = true,
      highlight_duration = 1,
      highlight_group = "ColorColumn",
      jumplist = 'left',
      notifications = true,
    })

    assert.stub(notify_stub).was.called(0)
    assert.stub(notify_once_stub).was.called(0)
  end)

  it("does not notify the user at all when some aren't present", function()
    local notify_stub = stub(vim, "notify")
    local notify_once_stub = stub(vim, "notify_once")

    tw.setup({
      highlight = true,
    })

    assert.stub(notify_stub).was.called(0)
    assert.stub(notify_once_stub).was.called(0)
  end)

  it("does not notify the user at all when given empty table", function()
    local notify_stub = stub(vim, "notify")
    local notify_once_stub = stub(vim, "notify_once")

    tw.setup({})

    assert.stub(notify_stub).was.called(0)
    assert.stub(notify_once_stub).was.called(0)
  end)

  it("does not notify the user at all when given no args", function()
    local notify_stub = stub(vim, "notify")
    local notify_once_stub = stub(vim, "notify_once")

    tw.setup()

    assert.stub(notify_stub).was.called(0)
    assert.stub(notify_once_stub).was.called(0)
  end)
end)

describe("Notifications", function()
  it("does not notify of bad ops when notifications is turned off", function()
    local notify_stub = stub(vim, "notify")
    local notify_once_stub = stub(vim, "notify_once")

    tw.setup({
      ---@diagnostic disable-next-line: assign-type-mismatch
      highlight = "butts", -- This will trigger a notification
      highlight_duration = 1,
      highlight_group = "ColorColumn",
      jumplist = 'left',
      notifications = false,
    })

    assert.stub(notify_stub).was.called(0)
    assert.stub(notify_once_stub).was.called(0)
  end)
end)
