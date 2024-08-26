using Givre
using Givre: EntityID, get_widget, get_entity, get_location, synchronize, Widget, to_rendering_coordinate_system, to_window_coordinate_system, exit
using CooperativeTasks: execute
using LinearAlgebra: norm
using XCB
using WindowAbstractions
using Test
using Logging: Logging
using MLStyle: @match
using StyledStrings: annotations, getface

Logging.disable_logging(Logging.Info)
ENV["GIVRE_LOG_FRAMECOUNT"] = false

include("virtual_inputs.jl")

# While executing this testset, do not provide any input of any sort to the windows that pop up.
# Otherwise, tests will fail due to unexpected interactions.

@testset "Application" begin
  @testset "Application start/exit" begin
    GC.gc()
    @test isa(sprint(show, Givre.app), String)
    main(async = true)
    synchronize()
    @test isa(sprint(show, app), String)
    @test app.ecs[app.windows[app.window], Givre.WINDOW_COMPONENT_ID] == app.window

    @testset "Location mapping" begin
      for location in [(0.0, 0.0), (0.0, 1.0), (1.0, 0.0), (1.0, 1.0), (0.5, 0.5), (0.4, 0.6)]
        location_2 = to_rendering_coordinate_system(location, app.window)
        @test collect(to_window_coordinate_system(location_2, app.window)) == collect(location)
      end
    end

    press_key(:AC01; modifiers = CTRL_MODIFIER)
    wait(app)
    @test istaskdone(app.task)
  end

  @testset "Interactions" begin
    GC.gc()
    CURSOR[] = (0.5, 0.5)
    main(async = true)
    synchronize()
    sleep(0.1)
    synchronize()

    # Menu.

    menu = get_widget(:file_menu)
    @test !menu.expanded

    move_cursor(menu)
    left_click()
    synchronize()
    @test menu.expanded
    @test Givre.active_item(menu) === nothing

    left_click()
    synchronize()
    @test !menu.expanded
    @test Givre.active_item(menu) === nothing

    left_click()
    synchronize()
    @test menu.expanded

    item_1 = menu.items[1]
    move_cursor(item_1)
    synchronize()
    @test Givre.active_item(menu) === item_1

    item_2 = menu.items[2]
    move_cursor(item_2)
    synchronize()
    @test Givre.active_item(menu) === item_2

    left_click()
    synchronize()
    @test !menu.expanded
    @test Givre.active_item(menu) === nothing

    ## Key-based navigation.
    move_cursor(menu)
    left_click()
    move_cursor(get_location(menu) .+ (1.0, 0.0))
    press_key(:UP)
    synchronize()
    @test Givre.active_item(menu) === menu.items[end]
    press_key(:UP)
    press_key(:RTRN)
    synchronize()
    @test Givre.active_item(menu) === nothing
    @test !menu.expanded

    move_cursor(menu)
    left_click()
    move_cursor(get_location(menu) .+ (1.0, 0.0))
    press_key(:UP)
    press_key(:UP)
    synchronize()
    @test count(Givre.isactive, menu.items) == 1
    @test Givre.active_item(menu) === menu.items[end - 1]
    press_key(:DOWN)
    synchronize()
    @test count(Givre.isactive, menu.items) == 1
    @test Givre.active_item(menu) === menu.items[end]
    move_cursor(item_1)
    synchronize()
    @test count(Givre.isactive, menu.items) == 1
    @test Givre.active_item(menu) === item_1
    press_key(:RTRN)
    synchronize()
    @test Givre.active_item(menu) === nothing
    @test !menu.expanded

    ## Wheel-based navigation.
    move_cursor(menu)
    left_click()
    move_cursor(get_location(menu) .+ (1.0, 0.0))
    scroll_up()
    synchronize()
    @test Givre.active_item(menu) === menu.items[end]
    scroll_down()
    synchronize()
    @test Givre.active_item(menu) === item_1
    press_key(:RTRN)
    synchronize()
    @test Givre.active_item(menu) === nothing
    @test !menu.expanded

    ## Shortcut navigation.
    move_cursor(menu)
    left_click()
    synchronize()
    @test menu.expanded
    press_key(:AB06)
    synchronize()
    @test !menu.expanded

    # Checkbox.

    checkbox = get_widget(:checkbox)
    @test !checkbox.value

    move_cursor(checkbox)
    left_click()
    synchronize()
    @test checkbox.value

    left_click()
    synchronize()
    @test !checkbox.value

    # Dragging.

    texture = get_entity(:texture)
    from = get_location(texture)
    move_cursor(texture)
    drag(from .+ 0.5)
    @test BUTTON_STATE[] == BUTTON_LEFT
    drop()
    @test BUTTON_STATE[] == BUTTON_NONE
    synchronize()
    to = get_location(texture)
    @test to - from ≈ [0.5, 0.5] atol=0.02

    # Shortcut display.

    (; text) = item_1.text
    @test annotations(text, 1) == []
    move_cursor(menu)
    left_click()
    press_key(:LALT)
    synchronize()
    @test annotations(text, 1) == [(1:1, :face => :application_shortcut_show)]
    face = getface(last.(annotations(text)))
    @test face.underline === true
    press_key(:LALT)
    synchronize()
    @test annotations(text, 1) == [(1:1, :face => :application_shortcut_hide)]
    face = getface(last.(annotations(text)))
    @test face.underline === false
    press_key(:LALT)
    synchronize()
    @test annotations(text, 1) == [(1:1, :face => :application_shortcut_show)]
    face = getface(last.(annotations(text)))
    @test face.underline === true
    left_click() # close menu
    synchronize()
    @test annotations(text, 1) == []

    move_cursor(menu)
    left_click()
    press_key(:AB02) # 'x' to exit
    wait(app)
    @test istaskdone(app.task)
  end
end;
