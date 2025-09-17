local pp = PlayerPedId()
local is_wants_to_boost = false
local boosting_coord = nil
local boosting_dest = nil
local prev_wants_to_boost = false
local active_boosters = {}
local nearest_booster = nil
local anim_booster = {'export@boosting_prepare', 'boosting_prepare'}
local anim_climber1 = {'anim@veh@plane@avenger@rhs@common@enter_exit', 'climb_up_no_door'}

CreateThread(function()
    while true do

        Wait(0)

        if IsPedInHighCover(pp) then --Check if near with a wall
            local playerCoords = GetEntityCoords(pp);
            local upCoords = playerCoords + vector3(0, 0, 3)
            local forward_vec = GetEntityForwardVector(pp)

            if IsPedInCoverFacingLeft(pp) then
                boosting_coord = upCoords + vector3(forward_vec.y, -forward_vec.x, forward_vec.z)*0.5
            else
                boosting_coord = upCoords + vector3(-forward_vec.y, forward_vec.x, forward_vec.z)*0.5
            end --Calculating vectors for teleport after boosting

            --debug lines
            /*
            DrawLine(playerCoords, upCoords, 0, 255, 0, 255)
            DrawLine(upCoords, boosting_coord, 0, 255, 0, 255)
            */
        end
    UpdateBoosterState()
    NotifyBoosterState()
    if is_wants_to_boost then
        ForcePedMotionState(pp, -294553821, true, 1, 1)
    end
    CheckIfCanClimb()
    Climb()

    end
end)

function UpdateBoosterState()
    if IsControlJustPressed(0, 20) then --Check for becoming a booster
        
        if is_wants_to_boost then
            StopAnimations()
            FreezeEntityPosition(pp, false)
            SetEntityCollision(pp, true, true)
            print('Not ready to boost anymore')
            is_wants_to_boost = false
        end

        if boosting_coord then
            local isFoundGround, groundZ = GetGroundZFor_3dCoord(boosting_coord.x, boosting_coord.y, boosting_coord.z, false);
            if isFoundGround and boosting_coord.z - groundZ <= 2 and (not is_wants_to_boost) and IsPedInHighCover(pp) then
                is_wants_to_boost = true
                if IsPedInCoverFacingLeft(pp) then
                    SetEntityHeading(pp, GetEntityHeading(pp) + 90)
                else
                    SetEntityHeading(pp, GetEntityHeading(pp) - 90)
                end
                FreezeEntityPosition(pp, true)
                SetEntityCollision(pp, false, false)
                SetEntityCoordsNoOffset(pp, GetEntityCoords(pp) - GetEntityForwardVector(pp) * 0.15 - vector3(0,0,0.08), false, false, false)
                PlayBoosterAnim()
                boosting_dest = vector3(boosting_coord.x, boosting_coord.y, groundZ - 0.5)
                print('Is ready to boost')
            end  
        end

    end
end

function PlayBoosterAnim() -- Play anim for booster
    RequestAnimDict(anim_booster[1])
    while not HasAnimDictLoaded(anim_booster[1]) do
        Wait(1)
    end
    TaskPlayAnim(pp, anim_booster[1], anim_booster[2], 1.0, 1.0, -1, 2, 0.0, true, true, false)
end

function NotifyBoosterState() --signalizing if booster state changed
    if prev_wants_to_boost ~= is_wants_to_boost then 
        TriggerServerEvent('boostingService:booster_state_changed', boosting_dest)
        prev_wants_to_boost = is_wants_to_boost
    end
end


function CheckIfCanClimb() -- Check if can climb with the nearest booster
    nearest_booster = nil
    for booster, _ in pairs(active_boosters) do
        local booster_ped = GetPlayerPed(GetPlayerFromServerId(booster))
        local distance = #(GetEntityCoords(booster_ped) - GetEntityCoords(pp))
        if distance < 1 and (not is_wants_to_boost) then
            nearest_booster = booster
        end
    end
end

function Climb() -- Climb, if player wants and booster nearby
    if nearest_booster and IsControlJustPressed(0, 20) and (GetPlayerFromServerId(nearest_booster) ~= PlayerId()) then
        FreezeEntityPosition(pp,true)
        booster_ped = GetPlayerPed(GetPlayerFromServerId(nearest_booster))
        booster_ped_forward_vec = GetEntityForwardVector(booster_ped)
        start_position = GetEntityCoords(booster_ped) + booster_ped_forward_vec * 0.8 + vector3(booster_ped_forward_vec.y, -booster_ped_forward_vec.x, booster_ped_forward_vec.z) * 0.2
        start_heading = GetEntityHeading(booster_ped) + 180
        SetEntityCoordsNoOffset(pp, start_position, true, false, false)
        SetEntityHeading(pp, start_heading)
        PlayClimberAnim()
        TriggerServerEvent('boostingService:started_climbing', active_boosters[nearest_booster])
        for time = 1, 50, 1 do
            Wait(5)
            SetEntityCoordsNoOffset(pp, GetEntityCoords(pp) + vector3(0, 0, 0.6 / 50), true, false, false)
        end
        SetEntityCoordsNoOffset(pp, active_boosters[nearest_booster] + booster_ped_forward_vec * 0.6, true, false, false)
        for time = 1, 50, 1 do
            Wait(8)
            SetEntityCoordsNoOffset(pp, GetEntityCoords(pp) + vector3(0, 0, 0.8 / 50), true, false, false)
        end
        SetEntityCoordsNoOffset(pp, active_boosters[nearest_booster] + vector3(0,0,1.5), true, true, true)
        ClearPedTasksImmediately(pp)
        FreezeEntityPosition(pp,false)
    end
end

function PlayClimberAnim() -- Play intro anim for climber
    RequestAnimDict(anim_climber1[1])
    while not HasAnimDictLoaded(anim_climber1[1]) do
        Wait(1)
    end
    TaskPlayAnim(pp, anim_climber1[1], anim_climber1[2], 4.0, 4.0, -1, 2, 0.0, true, true, false)
end

RegisterNetEvent('boostingService:sync_boosters') -- sync active boosters
AddEventHandler('boostingService:sync_boosters', function(new_active_boosters)
    active_boosters = new_active_boosters;
end)

RegisterNetEvent('boostingService:sync_climber') -- sync active climber
AddEventHandler('boostingService:sync_climber', function(climberId, destination)
    local climberPed = GetPlayerPed(GetPlayerFromServerId(climberId))
    local forward_vec = GetEntityForwardVector(climberPed)
    destination = destination - forward_vec + vector3(0, 0, 1.5)
    if climberPed ~= pp then
        for time = 1, 50, 1 do
            Wait(15)
            local coords = GetEntityCoords(climberPed)
            SetEntityCoordsNoOffset(climberPed, coords + (destination - coords) / 50, true, false, false)
        end
    end
end)

/*
RegisterCommand('playAnim', function(source, args)
    RequestAnimDict(args[1])
    Wait(100)
    TaskPlayAnim(pp, args[1], args[2], 4.0, 4.0, -1, 1, 0.0, false, false, false)
end)

RegisterCommand('stopAnim', function(source, args)
    ClearPedTasksImmediately(pp)
    SetEntityCollision(pp, true, true)
    FreezeEntityPosition(pp, false)
end)
*/
