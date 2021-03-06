Base         = require 'base'
Lists        = require '../views/lists'
TaskItem     = require '../views/task_item'
Task         = require '../models/task'
List         = require '../models/list'
Setting      = require '../models/setting'
keys         = require '../utils/keys'
dateDetector = require '../utils/date'
delay        = require '../utils/timer'
isMobile     = require '../utils/touch'

DURATION = 150 #ms

class Tasks extends Base.View

  template:
    item:     require '../templates/task'
    message: require '../templates/tasks'

  elements:
    '.tasks-container ul': 'tasks'
    '.task-input': 'input'
    '.message': 'message'

    '.entrance': 'entrance'

  events:
    'click': 'collapseOnClick'
    'keydown .task-input': 'keydown'
    'keyup .task-input': 'keyup'

  constructor: ->
    Base.touchify @events
    super

    @bind $ '.main'

    # Store currently loaded tasks
    @views = []
    @timers = {}

    @currentTask = null
    @search = false

    @listen [
      Task,
        'refresh': @refresh
        'create:model': @addOne
      List,
        'select:model': @render
      Setting,
        'change:sort': @render
    ]

  # Listen to events on the task item view
  bindTask: (view) =>
    view.on 'select', =>
      # Collapse the last open view
      @collapse()
      @currentTask = view

  # Add a single task to the DOM
  addOne: (task) =>
    # return unless List.current.id in [task.listId, 'all']

    # Add to dom
    @tasks.prepend @template.item task

    # Create a new view
    view = new TaskItem
      task: task
      el: @tasks.find "#task-#{ task.id }"

    # Bind events
    @bindTask(view)

    # TODO: Can we do this in the template?
    # view.el.addClass 'new'

    @views.push view

    # TODO: Set up a method for this
    @el.removeClass 'empty'

  # Render the current list
  refresh: =>
    @render List.current if List.current

  # Display a list of tasks
  render: (list, animated=false) =>

    if not animated

      @entrance.addClass 'exitPage'

      delay DURATION, =>
        @render(list, true)

      return

    if list.disabled
      @input.hide()
    else
      @input.show()

    # Search for tasks
    if list.id is 'search'

      @message.text @template.message.special
      if list.query? then @input.val list.query
      @toggleSearch on

      # toggleSearch will display the results for us
      return

    # If we were in search mode before, but the list isn't search
    # then turn off search mode
    else if @search
      @toggleSearch off

    # Standard list
    if list?.tasks
      tasks = list.tasks
      @message.text @template.message.standard

    # # Empty list
    else
      tasks = Task.list list.id
      @message.text @template.message.empty

    # Display tasks
    @displayTasks tasks

    # Handles Empty List
    @el.toggleClass 'empty', tasks.length is 0


  displayTasks: (tasks, disableAnimation=no) =>

    @entrance.removeClass('exitPage')

    unless disableAnimation
      @entrance.addClass('enterPage')

    # Keep a copy of the old views
    oldViews = @views
    @views = []

    # Unbind existing tasks
    delay 1000, =>
      for item in oldViews
        item.off 'select'
        item.release()
      oldViews = []

    # Holds html
    html = ''

    # TODO: Ignore this for now
    # Sorting tasks
    # if list.id in ['all', 'completed'] or Setting.sort

    #   tasks = Task.sortTasks(tasks)
    #   last = tasks[0]?.priority
    #   completed = tasks[0]?.completed

    #   for task in tasks

    #     # Add seperator if it is completed and the last one wasn't
    #     if completed and not task.completed
    #       completed = false
    #       task.group = yes

    #     # Add seperator if it is a different priority to the last one
    #     if not completed and task.priority isnt last
    #       task.group = yes

    #     last = task.priority

    #     if list.id is 'all'
    #       task.listName = List.get(task.list).name

    #     # Append html
    #     html = @template(task) + html

    # Not sorting
    # else

    tasks.forEach (task) =>
      html += @template.item task

      # TODO: Add this back in a sane way
      # if list.id is 'all' then task.listName = task.list().name

    # Render html
    @tasks.html html

    # Fade out animated stuff
    delay DURATION, =>
      @entrance.removeClass 'enterPage'
      @input.focus() unless isMobile

      tasks.forEach (task) =>
        view = new TaskItem
          task: task
          el: @tasks.find "#task-#{ task.id }"
        @bindTask view
        @views.push view

  # Toggles the input box text
  toggleSearch: (@search) =>
    message = if @search
      @updateSearchResults(no)
      @template.message.search
    else
      @template.message.addTask

    @input.attr 'placeholder', message

  # Handle keydown events on the input box
  keydown: (e) =>
    return if @search
    if e.keyCode is keys.enter and @input.val().length > 0
      @createNewTask()

  # Handle keyup events on the input box
  keyup: (e) =>
    if @search then @updateSearchResults()

  # Create a new task
  createNewTask: =>
    name = @input.val()
    @input.val ''
    Task.create
      name: name
      listId: Lists.active.id
      date: dateDetector.parse name

  updateSearchResults: (disableAnimation=yes) =>
    results = Task.search @input.val()
    @displayTasks results, disableAnimation
    @el.toggleClass 'empty', results.length is 0

  # ------------
  # COLLAPSE ALL
  # ------------

  collapse: =>
    @currentTask.collapse() if @currentTask

    # TODO: fix
    # if not List.current.disabled
    #   if Setting.sort
    #     @el.find('.expanded').draggable({ disabled: false })
    #   else
    #     @el.find('.expanded').parent().sortable({ disabled: false })

  # Collapsing of tasks
  collapseOnClick: (e) =>
    if e.target.className is 'main tasks'
      @collapse()

  # TODO: Refactor this
  setupSortable: ->
    self = this
    $(this.el[1]).sortable
      distance: 10
      scroll: false
      cursorAt:
        top: 15
        left: 30
      helper: (event, task) ->
        id = $(task).attr('id')
        element = "<div data-id=\'#{
          id }\' class=\'helper\'>#{
          $(task).find('.name').text() }</div>"
        $('body').append(element)
        $("[data-id=#{ id }]")
      update: ( event, ui ) ->
        arr = []
        $(this).children().each (index) ->
          arr.unshift $(this).attr('id').slice(5)
        self.list.updateAttribute('tasks', arr)

module.exports = Tasks
