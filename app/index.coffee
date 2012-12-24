require "lib/setup"
Spine = require "spine"

# Helpers
Keys = require "utils/keys"

# Models
Task    = require "models/task"
List    = require "models/list"
Setting = require "models/setting"

# Controllers
Tasks     = require "controllers/tasks"
Lists     = require "controllers/lists"
ListTitle = require "controllers/lists.title"
Panel     = require "controllers/panel"
Settings  = require "controllers/settings"
Auth      = require "controllers/auth"

class App extends Spine.Controller

  elements:
    '.tasks': 'tasksContainer'
    '.sidebar': 'listsContainer'
    '.tasks .title': 'listTitle'
    'header': 'panel'
    '.settings': 'settings'
    '.auth': 'auth'

  events:
    "keydown": "collapseAllOnEsc"

  constructor: ->
    super

    # Load settings
    Setting.fetch()
    if Setting.count() is 0
      Setting.create()

    # Init Auth
    new Auth
      el: @auth

    # Init panel
    new Panel
      el: @panel

    # Init settings
    window.settings = new Settings
      el: @settings

    # Init tasks
    @tasks = new Tasks( el: @tasksContainer )

    # Init lists
    @lists = new Lists( el: @listsContainer )
    new ListTitle
      el: @listTitle

    # Load data for localStorage
    List.fetch()
    Task.fetch()

    # Create inbox list
    if not !!List.exists("inbox")
      List.create
        id: "inbox"
        name: "Inbox"
        permanent: yes

    # Select the first list on load
    @lists.showInbox()

    # Login to sync
    Spine.Sync.login(Setting.first().username)

  collapseAllOnEsc: (e) =>
    if e.which is Keys.ESCAPE
      focusedInputs = $ "div:focus"
      if focusedInputs.length is 0
        @tasks.collapseAll()

module.exports = App
