local Players = game:GetService("Players")
local player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Настройки
local allClasses = {
	"Musician", "Miner", "Doctor", "Arsonist", "Necromancer", 
	"Packmaster", "Cowboy", "The Alamo", "Conductor", "Werewolf", 
	"High Roller", "Demolitionist", "Milkman", "Survivalist", 
	"Vampire", "Hunter", "Priest", "President", "Zombie", "Ironclad"
}

local allTrains = {"Cattle Car", "Passenger Train", "Gold Rush", "Armored Train", "Wooden Train", "Ghost Train"}

local giftBtnClass = None
local giftBtnTrain = None
local exitButtonText = "Exit"
local finalButtonText = ""
local finalButtonText_DEALID = ""
local scanDelay = 1
local scriptActive = false
local ironcladCompleted = false

-- Координаты для движения
local pathCoordinates = {
	Vector3.new(-101, 3.3, 170),
	Vector3.new(-101, 3.3, 140),
	Vector3.new(-28, 3.3, 140),
	Vector3.new(-28, 3.3, 170)
}

-- Настройки движения
local movementSettings = {
	precision = 5, -- Точность достижения точки
	walkSpeed = 50, -- Скорость ходьбы
	timeout = 10 -- Таймаут в секундах
}

-- Таблица для хранения всех созданных объектов
local scriptInstances = {}

-- Таблицы для хранения выбранных целей
local selectedClasses = {}
local selectedTrains = {}

-- Инициализация выбранных целей (по умолчанию все выбраны)
for _, class in ipairs(allClasses) do
	selectedClasses[class] = true
end
for _, train in ipairs(allTrains) do
	selectedTrains[train] = true
end

-- Проверка и удаление предыдущих экземпляров скрипта
if _G.AutoClickerRunning then
	warn("Обнаружен запущенный экземпляр AutoClicker. Очищаем предыдущий...")
	if _G.CleanupAutoClicker then
		_G.CleanupAutoClicker()
		task.wait(1) -- Даем время на очистку
	else
		warn("Функция CleanupAutoClicker не найдена. Возможно, предыдущий скрипт не был полностью удален.")
	end
end

-- Создаем интерфейс управления
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "Auto Gift Class/Train"
gui.ResetOnSpawn = false
table.insert(scriptInstances, gui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 300) -- Увеличиваем размер для чекбоксов
frame.Position = UDim2.new(0.85, -160, 0.15, 10)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true

-- Заголовок
local title = Instance.new("TextLabel", frame)
title.Text = "Auto Gift Class/Train"
title.Size = UDim2.new(1, 0, 0, 15)
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

-- Scroll frame для чекбоксов
local scrollFrame = Instance.new("ScrollingFrame", frame)
scrollFrame.Size = UDim2.new(1, -10, 0, 200)
scrollFrame.Position = UDim2.new(0, 5, 0.2, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600) -- Будем менять динамически
scrollFrame.ScrollBarThickness = 5

-- Поле для ввода никнейма
local finalTextInput = Instance.new("TextBox", frame)
finalTextInput.PlaceholderText = "Nickname"
finalTextInput.Text = finalButtonText
finalTextInput.Size = UDim2.new(0.8, 0, 0, 15)
finalTextInput.Position = UDim2.new(0.1, 0, 0.07, 0)
finalTextInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
finalTextInput.TextColor3 = Color3.new(1,1,1)

-- Поле для ввода никнейма
local finalTextInput2 = Instance.new("TextBox", frame)
finalTextInput2.PlaceholderText = "Second Nickname"
finalTextInput2.Text = finalButtonText
finalTextInput2.Size = UDim2.new(0.8, 0, 0, 15)
finalTextInput2.Position = UDim2.new(0.1, 0, 0.12, 0)
finalTextInput2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
finalTextInput2.TextColor3 = Color3.new(1,1,1)

-- Кнопка Start/Stop
local toggle = Instance.new("TextButton", frame)
toggle.Text = "Start"
toggle.Size = UDim2.new(0.8, 0, 0, 20)
toggle.Position = UDim2.new(0.1, 0, 0.23, 0)
toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)

-- Status работы
local status = Instance.new("TextLabel", frame)
status.Text = "Status: Pause"
status.Size = UDim2.new(1, 0, 0, 10)
status.Position = UDim2.new(0, 0, 0.18, 0)
status.TextColor3 = Color3.new(1,1,0)
status.BackgroundTransparency = 1

-- Кнопка очистки
local cleanupButton = Instance.new("TextButton", frame)
cleanupButton.Text = "X"
cleanupButton.Size = UDim2.new(0.08, 0, 0, 10)
cleanupButton.Position = UDim2.new(0.9, 0, 0.01, 0)
cleanupButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
table.insert(scriptInstances, cleanupButton)

-- Функция для создания чекбокса
local function createCheckbox(parent, text, yPosition, initialState, callback)
	local checkboxFrame = Instance.new("Frame", parent)
	checkboxFrame.Size = UDim2.new(1, 0, 0, 15)
	checkboxFrame.Position = UDim2.new(0, 0, 0, yPosition)
	checkboxFrame.BackgroundTransparency = 1

	local checkbox = Instance.new("TextButton", checkboxFrame)
	checkbox.Size = UDim2.new(0, 20, 0, 20)
	checkbox.Position = UDim2.new(0, 5, 0, 0)
	checkbox.Text = initialState and "o" or ""
	checkbox.TextColor3 = Color3.new(1, 1, 1)
	checkbox.BackgroundColor3 = initialState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 80)

	local label = Instance.new("TextLabel", checkboxFrame)
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 30, 0, 0)
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1

	checkbox.MouseButton1Click:Connect(function()
		local newState = checkbox.Text == ""
		checkbox.Text = newState and "o" or ""
		checkbox.BackgroundColor3 = newState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 80)
		callback(newState)
	end)

	return checkbox
end

-- Создаем чекбоксы для классов
local classesLabel = Instance.new("TextLabel", scrollFrame)
classesLabel.Text = "Classes:"
classesLabel.Size = UDim2.new(1, 0, 0, 10)
classesLabel.Position = UDim2.new(0, 0, 0, 0)
classesLabel.TextColor3 = Color3.new(1, 1, 1)
classesLabel.BackgroundTransparency = 1
classesLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопки для управления всеми классами
local classToggleFrame = Instance.new("Frame", scrollFrame)
classToggleFrame.Size = UDim2.new(1, 0, 0, 20)
classToggleFrame.Position = UDim2.new(0, 0, 0, 20)
classToggleFrame.BackgroundTransparency = 1

local enableAllClasses = Instance.new("TextButton", classToggleFrame)
enableAllClasses.Text = "On all"
enableAllClasses.Size = UDim2.new(0.35, 0, 0.8, 0)
enableAllClasses.Position = UDim2.new(0, 5, 0, 0)
enableAllClasses.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
enableAllClasses.TextColor3 = Color3.new(1,1,1)

local disableAllClasses = Instance.new("TextButton", classToggleFrame)
disableAllClasses.Text = "Off all"
disableAllClasses.Size = UDim2.new(0.35, 0, 0.8, 0)
disableAllClasses.Position = UDim2.new(0.5, 5, 0, 0)
disableAllClasses.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
disableAllClasses.TextColor3 = Color3.new(1,1,1)

-- Таблица для хранения чекбоксов классов
local classCheckboxes = {}
local yOffset = 40 -- Увеличиваем отступ для кнопок управления

for i, class in ipairs(allClasses) do
	local checkbox = createCheckbox(scrollFrame, class, yOffset, true, function(state)
		selectedClasses[class] = state
		print("Класс " .. class .. (state and " выбран" or " снят"))
	end)
	classCheckboxes[class] = checkbox
	yOffset = yOffset + 20
end

-- Обработчики для кнопок управления классами
enableAllClasses.MouseButton1Click:Connect(function()
	for class, checkbox in pairs(classCheckboxes) do
		if checkbox.Text == "" then
			checkbox.Text = "o"
			checkbox.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
			selectedClasses[class] = true
		end
	end
	print("Все классы включены")
end)

disableAllClasses.MouseButton1Click:Connect(function()
	for class, checkbox in pairs(classCheckboxes) do
		if checkbox.Text == "o" then
			checkbox.Text = ""
			checkbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			selectedClasses[class] = false
		end
	end
	print("Все классы выключены")
end)

-- Создаем чекбоксы для поездов
local trainsLabel = Instance.new("TextLabel", scrollFrame)
trainsLabel.Text = "Trains:"
trainsLabel.Size = UDim2.new(1, 0, 0, 20)
trainsLabel.Position = UDim2.new(0, 0, 0, yOffset)
trainsLabel.TextColor3 = Color3.new(1, 1, 1)
trainsLabel.BackgroundTransparency = 1
trainsLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопки для управления всеми поездами
local trainToggleFrame = Instance.new("Frame", scrollFrame)
trainToggleFrame.Size = UDim2.new(1, 0, 0, 20)
trainToggleFrame.Position = UDim2.new(0, 0, 0, yOffset + 20)
trainToggleFrame.BackgroundTransparency = 1

local enableAllTrains = Instance.new("TextButton", trainToggleFrame)
enableAllTrains.Text = "On all"
enableAllTrains.Size = UDim2.new(0.45, 0, 0.8, 0)
enableAllTrains.Position = UDim2.new(0, 5, 0, 0)
enableAllTrains.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
enableAllTrains.TextColor3 = Color3.new(1,1,1)

local disableAllTrains = Instance.new("TextButton", trainToggleFrame)
disableAllTrains.Text = "Off all"
disableAllTrains.Size = UDim2.new(0.45, 0, 0.8, 0)
disableAllTrains.Position = UDim2.new(0.5, 5, 0, 0)
disableAllTrains.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
disableAllTrains.TextColor3 = Color3.new(1,1,1)

yOffset = yOffset + 40 -- Увеличиваем отступ для кнопок управления

-- Таблица для хранения чекбоксов поездов
local trainCheckboxes = {}
for i, train in ipairs(allTrains) do
	local checkbox = createCheckbox(scrollFrame, train, yOffset, true, function(state)
		selectedTrains[train] = state
		print("Поезд " .. train .. (state and " выбран" or " снят"))
	end)
	trainCheckboxes[train] = checkbox
	yOffset = yOffset + 20
end

-- Обработчики для кнопок управления поездами
enableAllTrains.MouseButton1Click:Connect(function()
	for train, checkbox in pairs(trainCheckboxes) do
		if checkbox.Text == "" then
			checkbox.Text = "o"
			checkbox.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
			selectedTrains[train] = true
		end
	end
	print("Все поезда включены")
end)

disableAllTrains.MouseButton1Click:Connect(function()
	for train, checkbox in pairs(trainCheckboxes) do
		if checkbox.Text == "o" then
			checkbox.Text = ""
			checkbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			selectedTrains[train] = false
		end
	end
	print("Все поезда выключены")
end)



-- Обновляем размер CanvasSize
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

-- Обновляем finalButtonText при изменении текста в поле ввода
finalTextInput.FocusLost:Connect(function()
	finalButtonText = finalTextInput.Text
	local trimmedFinalText = finalButtonText:gsub("%s+", "") -- Убираем пробелы для проверки на пустоту

	if string.len(trimmedFinalText) > 0 then
		print("Ник для отслеживания обновлен на: '" .. finalButtonText .. "'", false)
		-- Если скрипт был остановлен и ждал нового ника, активируем его
		if not scriptActive then
			scriptActive = true
			toggle.Text = "Stop"
			toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			status.Text = "Status: Active"
			status.TextColor3 = Color3.new(0, 1, 0)
			print("Скрипт активирован после ввода нового ника.", false)
			_G.AutoClickerWaitingForPlayer = false -- Сбрасываем флаг, чтобы основной цикл начал работу
			toggle.Text = "Stop"
			toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			status.Text = "Status: Active"
			status.TextColor3 = Color3.new(0,1,0)
			print("Скрипт активирован")
		end
	else
		print("Поле ввода ника очищено. Скрипт Wait new nickname.", false)
		finalButtonText = "" -- Убедимся, что переменная тоже пустая
		scriptActive = false -- Останавливаем, если было активно, чтобы ждать ввода
		toggle.Text = "Start"
		toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		status.Text = "Status: Wait new nickname"
		status.TextColor3 = Color3.new(1, 1, 0)
	end
end)

-- Функция полной очистки
local function fullCleanup()
	scriptActive = false

	-- Удаляем все объекты в обратном порядке создания
	for i = #scriptInstances, 1, -1 do
		pcall(function()
			if scriptInstances[i] then
				scriptInstances[i]:Destroy()
			end
		end)
	end

	-- Очищаем таблицы
	table.clear(scriptInstances)

	-- Удаляем глобальные ссылки
	_G.AutoClickerRunning = nil
	_G.CleanupAutoClicker = nil
	_G.AutoClickerWaitingForPlayer = nil

	-- Выводим сообщение
	warn("Автокликер полностью удалён. Можно запускать новую версию.")
end

-- Обработчик кнопки очистки
cleanupButton.MouseButton1Click:Connect(fullCleanup)


-- Функция для создания полноэкранной блокирующей плашки
function CreateFullscreenOverlay()
	-- Проверяем, существует ли уже плашка, чтобы не создавать дубликаты
	if _G.FullscreenOverlay then return _G.FullscreenOverlay end

	-- Создаем экранный GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FullscreenOverlay"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true -- Растягиваем на весь экран, включая черные полосы

	-- Создаем фрейм для плашки
	local frame = Instance.new("Frame")
	frame.Name = "OverlayFrame"
	frame.Size = UDim2.new(1, 0, 1, 0) -- Полный экран
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0) -- Черный цвет
	frame.BackgroundTransparency = 0.5 -- Полупрозрачность
	frame.BorderSizePixel = 0

	-- Добавляем текст (опционально)
	local label = Instance.new("TextLabel")
	label.Name = "MessageLabel"
	label.Size = UDim2.new(0.8, 0, 0.2, 0)
	label.Position = UDim2.new(0.1, 0, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Text = "Не трогайте"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = frame

	-- Делаем фрейм кликабельным и блокирующим
	frame.Active = true -- Реагирует на клики
	frame.Selectable = true -- Может быть выбран
	frame.ZIndex = 9999 -- Очень высокий ZIndex чтобы быть поверх всего

	-- Прикрепляем фрейм к GUI
	frame.Parent = screenGui

	-- Включаем GUI для всех игроков (если скрипт выполняется на клиенте)
	if game:GetService("Players").LocalPlayer then
		screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	else
		-- Альтернативный вариант для серверного скрипта
		screenGui.Parent = game:GetService("StarterGui")
	end

	-- Сохраняем ссылку в _G для последующего управления
	_G.FullscreenOverlay = screenGui

	return screenGui
end

-- Функция для удаления плашки
function RemoveFullscreenOverlay()
	if _G.FullscreenOverlay then
		_G.FullscreenOverlay:Destroy()
		_G.FullscreenOverlay = nil
		return true
	end
	return false
end

-- Функция для проверки существования плашки
function HasFullscreenOverlay()
	return _G.FullscreenOverlay ~= nil
end

-- Функция для обновления текста плашки
function UpdateOverlayText(newText)
	if _G.FullscreenOverlay and _G.FullscreenOverlay:FindFirstChild("OverlayFrame") then
		local frame = _G.FullscreenOverlay.OverlayFrame
		if frame:FindFirstChild("MessageLabel") then
			frame.MessageLabel.Text = newText or "Доступ заблокирован"
			return true
		end
	end
	return false
end

-- Пример использования:
-- Создать плашку
-- CreateFullscreenOverlay()

-- Обновить текст (опционально)
-- UpdateOverlayText("Новый текст сообщения")

-- Удалить плашку (когда нужно)
-- RemoveFullscreenOverlay()














-- Функция для перемещения кнопки к центру экрана по Y
local function moveButtonToCenter(button)
	if not button or not button.AbsolutePosition then return false end

	-- Проверяем, является ли кнопка частью ScrollingFrame
	local parent = button.Parent
	while parent do
		if parent:IsA("ScrollingFrame") then               
			local currentPos = parent.CanvasPosition
			local parentHeight = parent.AbsoluteSize.Y
			local targetY = (parentHeight / 2)
			local buttonPosInFrame = button.AbsolutePosition.Y - parent.AbsolutePosition.Y + currentPos.Y  
			-- Плавно скроллим к нужной позиции
			for i = 1, 10 do
				parent.CanvasPosition = Vector2.new(button.AbsolutePosition.X, buttonPosInFrame-targetY)
				task.wait(0.02)
			end
			return true
		end
		parent = parent.Parent
	end

	-- Если это не ScrollingFrame, просто кликаем
	return false
end

-- Функция для нажатия клавиши E
local function pressE()
	VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(1)
	VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	print("Нажата клавиша E")
end

local function clickButton(button, status, maxAttempts)
    maxAttempts = maxAttempts or 3 -- Количество попыток по умолчанию
    local attempts = 0
    
    while attempts < maxAttempts do
        local success, err = pcall(function()
            if not button or not button:IsDescendantOf(game) or not button.AbsolutePosition then 
                error("Кнопка не найдена или уничтожена")
            end

            -- Перемещаем кнопку к центру (если нужно)
            moveButtonToCenter(button)
            task.wait(0.2) -- Увеличиваем задержку для анимации

            -- Рассчитываем позицию клика
            local absPos = button.AbsolutePosition
            local absSize = button.AbsoluteSize
            local center
            
            if status == "name" then
                center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y + absSize.Y + absSize.Y)
            elseif status == "exit" then
                center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y + absSize.Y)
            else
                center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y + absSize.Y + absSize.Y/1.55)
            end

            -- Плавное движение курсора
            for i = 1, 5 do
                VIM:SendMouseMoveEvent(
                    center.X + math.random(-5, 5), 
                    center.Y + math.random(-5, 5), 
                    game
                )
                task.wait(0.05)
            end

            -- Клик с небольшой случайной задержкой
            VIM:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
            task.wait(0.1 + math.random()*0.1)
            VIM:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
            
            return true
        end)

        if success then
            return true
        else
            print("Попытка "..tostring(attempts+1).." не удалась: "..tostring(err))
            attempts = attempts + 1
            task.wait(0.5) -- Увеличиваем задержку между попытками
        end
    end
    
    print("Не удалось кликнуть по кнопке после "..maxAttempts.." попыток")
    return false
end

-- Улучшенный поиск кнопок во всех возможных местах
local function findButton(textToFind, exactMatch, parent)
	parent = parent or game
	local elements = parent:GetDescendants()

	for _, element in pairs(elements) do
		if element:IsA("TextButton") and element.Visible and element.Text then
			local elementText = element.Text:gsub("%s+", ""):lower()
			local searchText = textToFind:gsub("%s+", ""):lower()

			if (exactMatch and elementText == searchText) or
				(not exactMatch and string.find(elementText, searchText)) then
				return element
			end
		end
	end

	-- Проверяем CoreGui на случай, если кнопка там
	if parent ~= CoreGui then
		local element = findButton(textToFind, exactMatch, CoreGui)
		if element then return element end
	end

	return nil
end

-- Функция для перемещения персонажа к точке
local function moveToPoint(position)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		print("Персонаж не найден!", true)
		return false
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		print("Humanoid не найден!", true)
		return false
	end

	-- Сохраняем оригинальную скорость
	local originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = movementSettings.walkSpeed

	humanoid:MoveTo(position)

	-- Ждём пока персонаж достигнет точки
	local startTime = os.clock()
	while (player.Character.HumanoidRootPart.Position - position).Magnitude > movementSettings.precision do
		if os.clock() - startTime > movementSettings.timeout then -- Таймаут
			print("Таймаут при движении к точке "..tostring(position), true)
			humanoid.WalkSpeed = originalSpeed
			return false
		end
		task.wait(0.1)
	end

	-- Восстанавливаем оригинальную скорость
	humanoid.WalkSpeed = originalSpeed
	return true
end

-- Функция для выполнения пути
local function followPath(coordinates, reverse)
	local path = reverse and {coordinates[4], coordinates[3], coordinates[2], coordinates[1]} or coordinates

	for _, point in ipairs(path) do
		if not scriptActive then break end
		print("Двигаемся к точке: "..tostring(point))
		if not moveToPoint(point) then
			break
		end
		task.wait(0.5) -- Pause между точками
	end
end

-- Функция для обработки кнопок поезда
local function handleTrainButtons()
	for train, isSelected in pairs(selectedTrains) do
		if not scriptActive then break end
		if isSelected then
			local targetBtn = findButton(train, false)
			if targetBtn then
				print("Найдена кнопка поезда: "..train)
				if clickButton(targetBtn, "other") then
					task.wait(0.1)      
					local giftBtnTrain = game:GetService("Players").LocalPlayer.PlayerGui.TrainSelection.TrainSelection.Options.TextButton
					if giftBtnTrain then
						if clickButton(giftBtnTrain, "other") then
							task.wait(0.1) 
							while true do
								if not scriptActive then break end
								local finalBtn = findButton(finalButtonText, false)
								if finalBtn then
									print("Найдена кнопка с никнеймом для поезда: "..finalButtonText)
									clickButton(finalBtn, "name")
									task.wait(0.3) 
									if game:GetService("Players").LocalPlayer.PlayerGui.GiftResponse.TextLabel.Visible then
										text_notif = game:GetService("Players").LocalPlayer.PlayerGui.GiftResponse.TextLabel.Text
										if string.find(string.lower(text_notif), string.lower("own")) then
											game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("📛🚂 Поезд "..train.." уже есть у игрока "..finalButtonText)
										else
											game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("✅🚂 Поезд "..train.." выдан игроку "..finalButtonText)
										end
										game:GetService("SoundService").Purchase.Playing = true
										wait(0.5)
										break
									end	
									clickButton(giftBtnTrain, "other")
									wait(0.1)
								end
							end
						end
					end
				end
			end
		end
	end
	local exitBtn = findButton(exitButtonText, true)
	if clickButton(exitBtn, "exit") then
		task.wait(0.1)
	end
end

-- Функция для поиска игрока по частичному нику
local function findPlayerByPartialName(partialName)
	if not partialName or partialName == "" then return nil end

	local searchLower = partialName:gsub("%s+", ""):lower() 

	for _, p in ipairs(Players:GetPlayers()) do
		local playerNameLower = p.Name:gsub("%s+", ""):lower()
		if string.find(playerNameLower, searchLower, 1, true) then 
			return p 
		end
	end
	return nil 
end

-- Функция для ожидания появления целевого игрока на сервере
local function waitForTargetPlayer(targetPartialName)

	print("Ожидаем появления игрока с ником '" .. targetPartialName .. "' на сервере...", false)
	status.Text = "Status: Wait user"
	status.TextColor3 = Color3.fromRGB(255, 165, 0) 

	while scriptActive do
		local foundPlayer = findPlayerByPartialName(targetPartialName)
		if foundPlayer then
			print("Игрок '" .. foundPlayer.Name .. "' найден! Запускаем основной цикл.", false)
			finalButtonText = foundPlayer.Name:gsub("%s+", ""):lower()
			playerNameLower = foundPlayer.Name:gsub("%s+", ""):lower()
			status.Text = "Status: Active (User id finded)"
			status.TextColor3 = Color3.new(0, 1, 0)
			return true 
		end
		task.wait(scanDelay) 
	end

	print("Wait user прервано (скрипт неActive).", true)
	return false 
end

-- Основная функция с улучшенной логикой
local function scanAndClick()
	-- Если Ironclad уже выполнен, работаем только с кнопками поезда
	if ironcladCompleted then
		-- Идем по координатам
		followPath(pathCoordinates)
		pressE()
		task.wait(1)

		-- Обрабатываем кнопки поезда
		handleTrainButtons()

		game:GetService("SoundService").Revolver.Playing = true
		game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("❗❗❗ ВНИМАНИЕ ❗❗❗ Уведомлений для поездов нету, поэтому проверьте их, зайдя к продавцу")
		game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("⭐ Все поезда и классы выданы игроку "..finalButtonText..". Жду подтверждение и отзыв) ❤")

		-- Возвращаемся обратно
		followPath(pathCoordinates, true)
		pressE()
		task.wait(1)

		if finalTextInput2.Text ~= "" then
			finalTextInput.Text = finalTextInput2.Text
			finalTextInput2.Text = ""
			print("Поле ввода никнейма кнопки заменено на второе, а оно очищено.", false)
		else
			finalTextInput.Text = ""
			print("Поле ввода никнейма кнопки очищено.", false)
		end


		-- Сбрасываем finalButtonText, чтобы основной цикл снова ждал ввода
		finalButtonText = ""
		finalButtonText_DEALID = ""
		print("Переменная finalButtonText сброшена. Скрипт Wait new nickname.", false)

		-- Переводим скрипт в состояние ожидания нового ввода / неактивности
		scriptActive = false 
		toggle.Text = "Start"
		toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		status.Text = "Status: Wait new nickname"
		status.TextColor3 = Color3.new(1, 1, 0) 

		ironcladCompleted = false 

		return
	end



	-- Обычная работа с выбранными классами
	for class, isSelected in pairs(selectedClasses) do
		if not scriptActive then break end
		if isSelected then
			local targetBtn = findButton(class, false)
			if targetBtn then
				print("Найдена целевая кнопка: " .. class)

				if clickButton(targetBtn, "other") then
					task.wait(0.1) 
					if giftBtnClass then
						if clickButton(giftBtnClass, "other") then
							task.wait(0.1) 
							while true do
								if not scriptActive then break end
								local finalBtn = findButton(finalButtonText, false)
								if finalBtn then
									print("Найдена кнопка с никнеймом: " .. finalButtonText)
									clickButton(finalBtn, "name")
									task.wait(0.3) 
									if game:GetService("Players").LocalPlayer.PlayerGui.GiftResponse.TextLabel.Visible then
										if class == "President" then class = "Президент"end
										text_notif = game:GetService("Players").LocalPlayer.PlayerGui.GiftResponse.TextLabel.Text
										if string.find(string.lower(text_notif), string.lower("own")) then
											game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("📛🧟‍♂️ Класс "..class.." уже есть у игрока "..finalButtonText)
										else
											game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("✅🧟‍♂️ Класс "..class.." выдан игроку "..finalButtonText)
										end
										game:GetService("SoundService").Purchase.Playing = true
										wait(0.5)
										break
									end	
									clickButton(giftBtnClass, "other")
									wait(0.1)
								end
							end
						end
					end
				end
			end
		end
	end
	local exitBtn = findButton(exitButtonText, true)
	if clickButton(exitBtn, "exit") then
		task.wait(0.1) 
	end
	ironcladCompleted = true
	print("Ironclad завершен, начинаем специальный процесс!")

end

-- Управление скриптом
toggle.MouseButton1Click:Connect(function()
	scriptActive = not scriptActive
	if scriptActive then
		toggle.Text = "Stop"
		toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		status.Text = "Status: Active"
		status.TextColor3 = Color3.new(0,1,0)
		print("Скрипт активирован")
	else
		toggle.Text = "Start"
		toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		status.Text = "Status: Pause"
		status.TextColor3 = Color3.new(1,1,0)
		print("Скрипт приостановлен")
	end
end)

-- Основной цикл
task.spawn(function()
	_G.AutoClickerWaitingForPlayer = false 

	while true do
		if scriptActive then
			print(1)
			local trimmedFinalText = finalButtonText:gsub("%s+", "")

			if string.len(trimmedFinalText) > 0 then 
				if not _G.AutoClickerWaitingForPlayer then 
					_G.AutoClickerWaitingForPlayer = true
					local playerFound = waitForTargetPlayer(trimmedFinalText) 
					_G.AutoClickerWaitingForPlayer = false 
					if not playerFound then
						print("Wait user прервано или игрок не найден. Скрипт остановлен до нового ввода ника.", true)
						scriptActive = false 
						toggle.Text = "Start"
						toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
						status.Text = "Status: Wait new nickname"
						status.TextColor3 = Color3.new(1, 1, 0)
						task.wait(scanDelay)
						continue 
					end
				end

				scanAndClick()
			else 
				print("Нет ника для отслеживания. Запускаем ScanAndClick без ожидания игрока.", false)
				scanAndClick()
			end
		else
			_G.AutoClickerWaitingForPlayer = false 
			status.Text = "Status: Wait new nickname"
			status.TextColor3 = Color3.new(1, 1, 0)
		end
		task.wait(scanDelay)
	end
end)

local function isGuiElementExists()
	local classSelection = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ClassSelection")
	if not classSelection then return false end

	local innerClassSelection = classSelection:FindFirstChild("ClassSelection")
	if not innerClassSelection then return false end

	local options = innerClassSelection:FindFirstChild("Options")
	if not options then return false end

	local textButton = options:FindFirstChild("TextButton")
	return textButton ~= nil
end

if isGuiElementExists() then
	giftBtnClass = game:GetService("Players").LocalPlayer.PlayerGui.ClassSelection.ClassSelection.Options.TextButton
else
	followPath(pathCoordinates, true)
	pressE()
	task.wait(1)
	giftBtnClass = game:GetService("Players").LocalPlayer.PlayerGui.ClassSelection.ClassSelection.Options.TextButton
end

-- В конец скрипта
_G.AutoClickerRunning = true

-- Также добавляем возможность удаления через консоль
_G.CleanupAutoClicker = fullCleanup
game:GetService("SoundService").Background.Playing = false
-- Инициализация
print("Автокликер успешно запущен!")



