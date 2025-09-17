local active_boosters = {}

RegisterServerEvent('boostingService:booster_state_changed')
AddEventHandler('boostingService:booster_state_changed', function(boosting_coord)
    if active_boosters[source] == nil then
        active_boosters[source] = boosting_coord
    else
        active_boosters[source] = nil
    end
    Citizen.Trace('boostingService:: Player' ..GetPlayerName(source).. 'is become booster.')
    TriggerClientEvent('boostingService:sync_boosters', -1, active_boosters)
end)

AddEventHandler('playerJoining', function()
    TriggerClientEvent('boostingService:sync_boosters', -1, active_boosters)
    Citizen.Trace('boostingService:: All active boosters are synced for joined player.')
end)

AddEventHandler('playerDropped', function (reason, resourceName, clientDropReason)
    if active_boosters[source] ~= nil then
        active_boosters[source] = nil
        Citizen.Trace('boostingService:: Player' ..GetPlayerName(source).. 'was deleted from active boosters because of dropping.')
    end
end)

RegisterServerEvent('boostingService:started_climbing')
AddEventHandler('boostingService:started_climbing', function(destination)
    TriggerClientEvent('boostingService:sync_climber', -1, source, destination)
end)