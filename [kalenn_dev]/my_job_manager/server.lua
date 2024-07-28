ESX = exports['es_extended']:getSharedObject()

if not ESX then
    print('Erreur: ESX n\'a pas été correctement chargé.')
    return
end

-- Fonction pour obtenir le prochain numéro de grade disponible pour un job
local function getNextGrade(jobName, callback)
    exports.oxmysql:fetch('SELECT MAX(grade) as maxGrade FROM job_grades WHERE job_name = ?', { jobName }, function(result)
        local nextGrade = 0
        if result[1] and result[1].maxGrade then
            nextGrade = result[1].maxGrade + 1
        end
        callback(nextGrade)
    end)
end

-- Création d'un job avec un grade par défaut
RegisterServerEvent('my_job_manager:createJob')
AddEventHandler('my_job_manager:createJob', function(jobName, jobLabel, gradeName, gradeLabel)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        -- Insertion du job dans la base de données
        exports.oxmysql:execute('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, ?)', {
            jobName,
            jobLabel,
            0  -- Assumé comme non-whitelisted par défaut
        }, function(result)
            if result.affectedRows and result.affectedRows > 0 then
                -- Insertion du job dans job_admin
                exports.oxmysql:execute('INSERT INTO job_admin (job_name) VALUES (?)', {
                    jobName
                }, function(result2)
                    if result2.affectedRows and result2.affectedRows > 0 then
                        -- Obtenir le prochain numéro de grade disponible
                        getNextGrade(jobName, function(nextGrade)
                            -- Création du grade par défaut pour le job nouvellement créé
                            exports.oxmysql:execute('INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                                jobName,
                                nextGrade,
                                gradeName,
                                gradeLabel,
                                0,  -- Salaire initial
                                '{}',  -- Remplacer par les données de skin si nécessaire
                                '{}'
                            }, function(result3)
                                if result3.affectedRows and result3.affectedRows > 0 then
                                    xPlayer.showNotification('Le job ~g~' .. jobLabel .. '~s~ et le grade ~g~' .. gradeLabel .. '~s~ ont été créés avec succès.')
                                else
                                    xPlayer.showNotification('~r~Erreur:~s~ le grade n\'a pas pu être créé pour le nouveau job.')
                                end
                            end)
                        end)
                    else
                        xPlayer.showNotification('~r~Erreur:~s~ le job n\'a pas pu être ajouté à la table job_admin.')
                    end
                end)
            else
                xPlayer.showNotification('~r~Erreur:~s~ le job n\'a pas pu être créé.')
            end
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Suppression d'un job
RegisterServerEvent('my_job_manager:deleteJob')
AddEventHandler('my_job_manager:deleteJob', function(jobName, deleteGrades)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        local function deleteJob()
            exports.oxmysql:execute('DELETE FROM jobs WHERE name = ?', { jobName }, function(result)
                if result.affectedRows and result.affectedRows > 0 then
                    exports.oxmysql:execute('DELETE FROM job_admin WHERE job_name = ?', { jobName }, function(result2)
                        if result2.affectedRows and result2.affectedRows > 0 then
                            xPlayer.showNotification('Le job et ses blips associés ont été supprimés.')
                        else
                            xPlayer.showNotification('~r~Erreur:~s~ le job a été supprimé, mais pas les blips associés.')
                        end
                    end)
                else
                    xPlayer.showNotification('~r~Erreur:~s~ le job n\'a pas pu être supprimé.')
                end
            end)
        end

        if deleteGrades then
            exports.oxmysql:execute('DELETE FROM job_grades WHERE job_name = ?', { jobName }, function(result)
                if result.affectedRows and result.affectedRows > 0 then
                    deleteJob()
                else
                    xPlayer.showNotification('~r~Erreur:~s~ les grades n\'ont pas pu être supprimés.')
                end
            end)
        else
            deleteJob()
        end
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Création d'un grade pour un job
RegisterServerEvent('my_job_manager:createGrade')
AddEventHandler('my_job_manager:createGrade', function(jobName, gradeName, gradeLabel, salary)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        -- Obtenir le prochain numéro de grade disponible
        getNextGrade(jobName, function(nextGrade)
            exports.oxmysql:execute('INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                jobName,
                nextGrade,
                gradeName,
                gradeLabel,
                salary,
                '{}',  -- Remplacer par les données de skin si nécessaire
                '{}'
            }, function(result)
                if result.affectedRows and result.affectedRows > 0 then
                    xPlayer.showNotification('Le grade ~g~' .. gradeLabel .. '~s~ a été créé pour le job ' .. jobName .. '.')
                else
                    xPlayer.showNotification('~r~Erreur:~s~ le grade n\'a pas pu être créé.')
                end
            end)
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Suppression d'un grade pour un job
RegisterServerEvent('my_job_manager:deleteGrade')
AddEventHandler('my_job_manager:deleteGrade', function(jobName, gradeName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        exports.oxmysql:execute('DELETE FROM job_grades WHERE job_name = ? AND name = ?', {
            jobName,
            gradeName
        }, function(result)
            if result.affectedRows and result.affectedRows > 0 then
                xPlayer.showNotification('Le grade ~r~' .. gradeName .. '~s~ a été supprimé pour le job ' .. jobName .. '.')
            else
                xPlayer.showNotification('~r~Erreur:~s~ le grade n\'a pas pu être supprimé.')
            end
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Mise à jour de l'emplacement du blip
RegisterServerEvent('my_job_manager:updateBlipLocation')
AddEventHandler('my_job_manager:updateBlipLocation', function(coords)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        exports.oxmysql:execute('UPDATE job_admin SET blip_x = ?, blip_y = ?, blip_z = ? WHERE job_name = ?', { coords.x, coords.y, coords.z, xPlayer.job.name }, function(result)
            if result.affectedRows and result.affectedRows > 0 then
                xPlayer.showNotification('L\'emplacement du blip a été mis à jour.')
            else
                xPlayer.showNotification('~r~Erreur:~s~ l\'emplacement du blip n\'a pas pu être mis à jour.')
            end
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Mise à jour du type de blip
RegisterServerEvent('my_job_manager:updateBlipType')
AddEventHandler('my_job_manager:updateBlipType', function(blipId, blipSize)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        exports.oxmysql:execute('UPDATE job_admin SET blip_id = ?, blip_size = ? WHERE job_name = ?', { blipId, blipSize, xPlayer.job.name }, function(result)
            if result.affectedRows and result.affectedRows > 0 then
                xPlayer.showNotification('Le type de blip a été mis à jour.')
            else
                xPlayer.showNotification('~r~Erreur:~s~ le type de blip n\'a pas pu être mis à jour.')
            end
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Mise à jour de la couleur du blip
RegisterServerEvent('my_job_manager:updateBlipColor')
AddEventHandler('my_job_manager:updateBlipColor', function(colorId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        exports.oxmysql:execute('UPDATE job_admin SET blip_color = ? WHERE job_name = ?', { colorId, xPlayer.job.name }, function(result)
            if result.affectedRows and result.affectedRows > 0 then
                xPlayer.showNotification('La couleur du blip a été mise à jour.')
            else
                xPlayer.showNotification('~r~Erreur:~s~ la couleur du blip n\'a pas pu être mise à jour.')
            end
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Mise à jour de la visibilité du blip
RegisterServerEvent('my_job_manager:updateBlipVisibility')
AddEventHandler('my_job_manager:updateBlipVisibility', function(visibility)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        exports.oxmysql:execute('UPDATE job_admin SET visibility = ? WHERE job_name = ?', { visibility, xPlayer.job.name }, function(result)
            if result.affectedRows and result.affectedRows > 0 then
                xPlayer.showNotification('La visibilité du blip a été mise à jour.')
            else
                xPlayer.showNotification('~r~Erreur:~s~ la visibilité du blip n\'a pas pu être mise à jour.')
            end
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)

-- Liste des jobs
RegisterServerEvent('my_job_manager:listJobs')
AddEventHandler('my_job_manager:listJobs', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.getGroup() == 'admin' then
        exports.oxmysql:fetch('SELECT name, label FROM jobs', {}, function(jobs)
            TriggerClientEvent('my_job_manager:showJobs', xPlayer.source, jobs)
        end)
    else
        xPlayer.showNotification('~r~Vous n\'avez pas la permission de faire ça.')
    end
end)
