ESX = exports['es_extended']:getSharedObject()
local jobBlips = {}

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(100)
    end

    TriggerServerEvent('my_job_manager:requestBlips')
end)

RegisterNetEvent('my_job_manager:sendBlips')
AddEventHandler('my_job_manager:sendBlips', function(blips)
    for _, blip in ipairs(jobBlips) do
        RemoveBlip(blip)
    end
    jobBlips = {}

    for _, jobBlip in ipairs(blips) do
        local blip = AddBlipForCoord(jobBlip.blip_x, jobBlip.blip_y, jobBlip.blip_z)
        SetBlipSprite(blip, jobBlip.blip_id)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, jobBlip.blip_size)
        SetBlipColour(blip, jobBlip.blip_color)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(jobBlip.job_name)
        EndTextCommandSetBlipName(blip)

        table.insert(jobBlips, blip)
    end
end)

RegisterCommand('jobadmin', function()
    openAdminMenu()
end, false)

function openAdminMenu()
    local elements = {
        {label = 'Créer un nouveau job', value = 'create_job'},
        {label = 'Supprimer un job', value = 'delete_job'},
        {label = 'Modifier un job', value = 'modify_job'},
        {label = 'Liste des Jobs', value = 'list_jobs'}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'admin_job_menu', {
        title    = 'Gestion des Jobs',
        align    = 'top-left',
        elements = elements
    }, function(data, menu)
        local action = data.current.value

        if action == 'create_job' then
            createJob()
        elseif action == 'delete_job' then
            deleteJob()
        elseif action == 'modify_job' then
            selectJobToModify()
        elseif action == 'list_jobs' then
            listJobs()
        end

    end, function(data, menu)
        menu.close()
    end)
end

function createJob()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'create_job_name_dialog', {
        title = "Nom du nouveau job"
    }, function(data, menu)
        local jobName = data.value

        if jobName == nil or jobName == '' then
            ESX.ShowNotification('Nom de job invalide')
        else
            menu.close()
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'create_job_label_dialog', {
                title = "Label du nouveau job"
            }, function(data2, menu2)
                local jobLabel = data2.value

                if jobLabel == nil or jobLabel == '' then
                    ESX.ShowNotification('Label de job invalide')
                else
                    menu2.close()
                    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'create_grade_name_dialog', {
                        title = "Nom du premier grade"
                    }, function(data3, menu3)
                        local gradeName = data3.value

                        if gradeName == nil or gradeName == '' then
                            ESX.ShowNotification('Nom de grade invalide')
                        else
                            menu3.close()
                            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'create_grade_label_dialog', {
                                title = "Label du premier grade"
                            }, function(data4, menu4)
                                local gradeLabel = data4.value

                                if gradeLabel == nil ou gradeLabel == '' then
                                    ESX.ShowNotification('Label de grade invalide')
                                else
                                    menu4.close()
                                    TriggerServerEvent('my_job_manager:createJob', jobName, jobLabel, gradeName, gradeLabel)
                                end
                            end, function(data4, menu4)
                                menu4.close()
                            end)
                        end
                    end, function(data3, menu3)
                        menu3.close()
                    end)
                end
            end, function(data2, menu2)
                menu2.close()
            end)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function deleteJob()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'delete_job_dialog', {
        title = "Nom du job à supprimer"
    }, function(data, menu)
        local jobName = data.value

        if jobName == nil ou jobName == '' then
            ESX.ShowNotification('Nom de job invalide')
        else
            menu.close()
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'delete_job_options', {
                title = 'Options de suppression',
                align = 'top-left',
                elements = {
                    {label = 'Supprimer les grades', value = 'delete_grades'},
                    {label = 'Ne pas supprimer les grades', value = 'keep_grades'}
                }
            }, function(data2, menu2)
                local option = data2.current.value
                menu2.close()
                TriggerServerEvent('my_job_manager:deleteJob', jobName, option == 'delete_grades')
            end, function(data2, menu2)
                menu2.close()
            end)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function selectJobToModify()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'select_job_dialog', {
        title = "Nom du job à modifier"
    }, function(data, menu)
        local jobName = data.value

        if jobName == nil ou jobName == '' then
            ESX.ShowNotification('Nom de job invalide')
        else
            menu.close()
            openJobModificationMenu(jobName)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openJobModificationMenu(jobName)
    local elements = {
        {label = 'Créer un grade', value = 'create_grade'},
        {label = 'Supprimer un grade', value = 'delete_grade'},
        {label = 'Modifier blip', value = 'modify_blip'}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'job_modification_menu', {
        title    = 'Modifier ' .. jobName,
        align    = 'top-left',
        elements = elements
    }, function(data, menu)
        local action = data.current.value

        if action == 'create_grade' then
            createGrade(jobName)
        elseif action == 'delete_grade' then
            deleteGrade(jobName)
        elseif action == 'modify_blip' then
            modifyBlipMenu(jobName)
        end

    end, function(data, menu)
        menu.close()
    end)
end

function createGrade(jobName)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'create_grade_dialog', {
        title = "Nom du nouveau grade"
    }, function(data, menu)
        local gradeName = data.value

        if gradeName == nil ou gradeName == '' then
            ESX.ShowNotification('Nom de grade invalide')
        else
            menu.close()
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'create_grade_label_dialog', {
                title = "Label du nouveau grade"
            }, function(data2, menu2)
                local gradeLabel = data2.value

                if gradeLabel == nil ou gradeLabel == '' then
                    ESX.ShowNotification('Label de grade invalide')
                else
                    menu2.close()
                    TriggerServerEvent('my_job_manager:createGrade', jobName, gradeName, gradeLabel, 0, 0)  -- Ajustez si nécessaire
                end
            end, function(data2, menu2)
                menu2.close()
            end)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function deleteGrade(jobName)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'delete_grade_dialog', {
        title = "Nom du grade à supprimer"
    }, function(data, menu)
        local gradeName = data.value

        if gradeName == nil ou gradeName == '' then
            ESX.ShowNotification('Nom de grade invalide')
        else
            menu.close()
            TriggerServerEvent('my_job_manager:deleteGrade', jobName, gradeName)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function modifyBlipMenu(jobName)
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'modify_blip_menu', {
        title = 'Modifier blip pour ' .. jobName,
        align = 'top-left',
        elements = {
            {label = 'Emplacement', value = 'location'},
            {label = 'Type de blip', value = 'type'},
            {label = 'Couleur du blip', value = 'color'},
            {label = 'Visibilité', value = 'visibility'}
        }
    }, function(data, menu)
        local action = data.current.value

        if action == 'location' then
            modifyBlipLocation(jobName)
        elseif action == 'type' then
            modifyBlipType(jobName)
        elseif action == 'color' then
            modifyBlipColor(jobName)
        elseif action == 'visibility' then
            modifyBlipVisibility(jobName)
        end

    end, function(data, menu)
        menu.close()
    end)
end

function modifyBlipLocation(jobName)
    ESX.ShowNotification('Déplacez-vous à l\'emplacement souhaité et appuyez sur E pour confirmer.')
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if IsControlJustReleased(0, 38) then -- E key
                local playerCoords = GetEntityCoords(PlayerPedId())
                print('Coordinates to update:', playerCoords.x, playerCoords.y, playerCoords.z)
                TriggerServerEvent('my_job_manager:updateBlipLocation', jobName, playerCoords)
                break
            end
        end
    end)
end

function modifyBlipType(jobName)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'modify_blip_type_dialog', {
        title = 'Entrez l\'ID du blip et la taille (séparés par une virgule)'
    }, function(data, menu)
        local input = data.value
        if input == nil ou input == '' then
            ESX.ShowNotification('Entrée invalide')
        else
            local blipId, blipSize = string.match(input, '(%d+),(%d+)')
            if blipId and blipSize then
                TriggerServerEvent('my_job_manager:updateBlipType', jobName, tonumber(blipId), tonumber(blipSize))
                menu.close()
            else
                ESX.ShowNotification('Format invalide, veuillez utiliser ID,Taille')
            end
        end
    end, function(data, menu)
        menu.close()
    end)
end

function modifyBlipColor(jobName)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'modify_blip_color_dialog', {
        title = 'Entrez l\'ID de la couleur du blip'
    }, function(data, menu)
        local colorId = tonumber(data.value)
        if colorId == nil then
            ESX.ShowNotification('Entrée invalide')
        else
            TriggerServerEvent('my_job_manager:updateBlipColor', jobName, colorId)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function modifyBlipVisibility(jobName)
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'modify_blip_visibility_menu', {
        title = 'Visibilité du blip',
        align = 'top-left',
        elements = {
            {label = 'Tous les joueurs', value = 'all'},
            {label = 'Seulement les joueurs avec le job', value = 'job'},
            {label = 'Personne', value = 'none'}
        }
    }, function(data, menu)
        local visibility = data.current.value
        TriggerServerEvent('my_job_manager:updateBlipVisibility', jobName, visibility)
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end

function listJobs()
    TriggerServerEvent('my_job_manager:listJobs')
end

RegisterNetEvent('my_job_manager:showJobs')
AddEventHandler('my_job_manager:showJobs', function(jobs)
    local elements = {}

    for _, job in ipairs(jobs) do
        table.insert(elements, {label = job.label, value = job.name})
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'job_list', {
        title = 'Liste des Jobs',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        -- Aucune action nécessaire, juste afficher la liste
    end, function(data, menu)
        menu.close()
    end)
end)