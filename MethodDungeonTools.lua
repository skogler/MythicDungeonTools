
local AddonName, MethodDungeonTools = ...



local mainFrameStrata = "HIGH"
local canvasDrawLayer = "BORDER"
local blipDrawLayer = "OVERLAY"

_G["MethodDungeonTools"] = MethodDungeonTools

local twipe,tinsert,tremove,tgetn,CreateFrame,tonumber,pi,max,min,atan2,abs,pairs,ipairs,GetCursorPosition,GameTooltip = table.wipe,table.insert,table.remove,table.getn,CreateFrame,tonumber,math.pi,math.max,math.min,math.atan2,math.abs,pairs,ipairs,GetCursorPosition,GameTooltip

local sizex = 840
local sizey = 555
local buttonTextFontSize = 12
local methodColor = "|cFFF49D38"
local selectedGreen = {0,1,0,0.4}
selectedGreen = {34/255,139/255,34/255,0.7}
MethodDungeonTools.BackdropColor = {0.058823399245739,0.058823399245739,0.058823399245739,0.9}

local Dialog = LibStub("LibDialog-1.0")
local AceGUI = LibStub("AceGUI-3.0")
local db
local icon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("MethodDungeonTools", {
	type = "data source",
	text = "Method Dungeon Tools",
	icon = "Interface\\AddOns\\MethodDungeonTools\\Textures\\MethodMinimap",
	OnClick = function(button,buttonPressed)
		if buttonPressed == "RightButton" then
			if db.minimap.lock then
				icon:Unlock("MethodDungeonTools")
			else
				icon:Lock("MethodDungeonTools")
			end
		else
			MethodDungeonTools:ShowInterface()
		end
	end,
	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		tooltip:AddLine(methodColor.."Method Dungeon Tools|r")
		tooltip:AddLine("Click to toggle AddOn Window")
		tooltip:AddLine("Right-click to lock Minimap Button")
	end,
})

local SetPortraitTextureFromCreatureDisplayID,MouseIsOver = SetPortraitTextureFromCreatureDisplayID,MouseIsOver

-- Made by: Nnogga - Tarren Mill <Method>, 2017-2018

SLASH_METHODDUNGEONTOOLS1 = "/mplus"
SLASH_METHODDUNGEONTOOLS2 = "/mdt"
SLASH_METHODDUNGEONTOOLS3 = "/methoddungeontools"

--LUA API
local pi,tinsert = math.pi,table.insert

function SlashCmdList.METHODDUNGEONTOOLS(cmd, editbox)
	local rqst, arg = strsplit(' ', cmd)
	if rqst == "devmode" then
		MethodDungeonTools:ToggleDevMode()
	elseif rqst == "remove" then
		--
	else
		MethodDungeonTools:ShowInterface()
	end
end

local initFrames
-------------------------
--- Saved Variables  ----
-------------------------
local defaultSavedVars = {
	global = {
		currentExpansion = 1,
        enemyForcesFormat = 2,
		currentDungeonIdx = 1,
		currentDifficulty = 15,
		xoffset = 0,
		yoffset = -150,
		anchorFrom = "TOP",
		anchorTo = "TOP",
        tooltipInCorner = false,
		minimap = {
			hide = false,
		},
        toolbar ={
            color = {r=1,g=1,b=1,a=1},
            brushSize = 3,
        },
		presets = {},
		currentPreset = {},
	},
}
do
    for i=1,24 do
        defaultSavedVars.global.presets[i] = {
            [1] = {text="Default",value={}},
            [2] = {text="<New Preset>",value=0},
        }
        defaultSavedVars.global.currentPreset[i] = 1
    end
end


-- Init db
do
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, ...)
        return MethodDungeonTools[event](self,...)
    end)

    function MethodDungeonTools.ADDON_LOADED(self,addon)
        if addon == "MethodDungeonTools" then
			db = LibStub("AceDB-3.0"):New("MethodDungeonToolsDB", defaultSavedVars).global
			initFrames()
			icon:Register("MethodDungeonTools", LDB, db.minimap)
			if not db.minimap.hide then
				icon:Show("MethodDungeonTools")
			end
			Dialog:Register("MethodDungeonToolsPosCopyDialog", {
				text = "Pos Copy",
				width = 500,
				editboxes = {
					{ width = 484,
					  on_escape_pressed = function(self, data) self:GetParent():Hide() end,
					},
				},
				on_show = function(self, data)
					self.editboxes[1]:SetText(data.pos)
					self.editboxes[1]:HighlightText()
					self.editboxes[1]:SetFocus()
				end,
				buttons = {
					{ text = CLOSE, },
				},
				show_while_dead = true,
				hide_on_escape = true,
			})
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end

local dungeonEnemyBlips
local numDungeonEnemyBlips = 0
local tooltip
local tooltipLastShown
local dungeonEnemiesSelected = {}
MethodDungeonTools.dungeonTotalCount = {}
MethodDungeonTools.pencilBlips = {}

local dungeonList = {
    [1] = "Black Rook Hold",
    [2] = "Cathedral of Eternal Night",
    [3] = "Court of Stars",
    [4] = "Darkheart Thicket",
    [5] = "Eye of Azshara",
    [6] = "Halls of Valor",
    [7] = "Maw of Souls",
    [8] = "Neltharion's Lair",
    [9] = "Return to Karazhan Lower",
    [10] = "Return to Karazhan Upper",
    [11] = "Seat of the Triumvirate",
    [12] = "The Arcway",
    [13] = "Vault of the Wardens",
    [14] = " >Battle for Azeroth",
    [15] = "Atal'Dazar",
    [16] = "Freehold",
    [17] = "Kings' Rest",
    [18] = "Shrine of the Storm",
    [19] = "Siege of Boralus",
    [20] = "Temple of Sethraliss",
    [21] = "The MOTHERLODE!!",
    [22] = "The Underrot",
    [23] = "Tol Dagor",
    [24] = "Waycrest Manor",
    [25] = " >Legion",
}

local dungeonSubLevels = {
    [1] = {
        [1] = "The Ravenscrypt",
        [2] = "The Grand Hall",
        [3] = "Ravenshold",
        [4] = "The Rook's Host",
        [5] = "Lord Ravencrest's Chamber",
        [6] = "The Raven's Crown",
    },
    [2] = {
        [1] = "Hall of the Moon",
        [2] = "Twilight Grove",
        [3] = "The Emerald Archives",
        [4] = "Path of Illumination",
        [5] = "Sacristy of Elune",
    },
    [3] = {
        [1] = "Court of Stars",
        [2] = "The Jeweled Estate",
        [3] = "The Balconies",
    },
    [4] = {
        [1] = "Darkheart Thicket",
    },
    [5] = {
        [1] = "Eye of Azshara",
    },
    [6] = {
        [1] = "The High Gate",
        [2] = "Field of the Eternal Hunt",
        [3] = "Halls of Valor",
    },
    [7] = {
        [1] = "Helmouth Cliffs",
        [2] = "The Hold",
        [3] = "The Naglfar",
    },
    [8] = {
        [1] = "Neltharion's Lair",
    },
    [9] = {
        [1] = "Master's Terrace",
        [2] = "Opera Hall Balcony",
        [3] = "The Guest Chambers",
        [4] = "The Banquet Hall",
        [5] = "Upper Livery Stables",
        [6] = "The Servant's Quarters",
    },
    [10] = {
        [1] = "Lower Broken Stair",
        [2] = "Upper Broken Stair",
        [3] = "The Menagerie",
        [4] = "Guardian's Library",
        [5] = "Library Floor",
        [6] = "Upper Library",
        [7] = "Gamesman's Hall",
        [8] = "Netherspace",
    },
    [11] = {
        [1] = "Seat of the Triumvirate",
    },
    [12] = {
        [1] = "The Arcway",
    },
    [13] = {
        [1] = "The Warden's Court",
        [2] = "Vault of the Wardens",
        [3] = "Vault of the Betrayer",
    },
    [15] = {
        [1] = "Atal'Dazar",
        [2] = "Sacrificial Pits",
    },
    [16] = {
        [1] = "Freehold",
    },
    [17] = {
        [1] = "Kings' Rest",
    },
    [18] = {
        [1] = "Shrine of the Storm",
        [2] = "Shrine Interior TEMP",
    },
    [19] = {
        [1] = "Siege of Boralus",
    },
    [20] = {
        [1] = "Temple of Sethraliss",
        [2] = "Atrium of Sethraliss",
    },
    [21] = {
        [1] = "The MOTHERLODE!!",
    },
    [22] = {
        [1] = "The Underrot",
        [2] = "Temple Interior TEMP",
    },
    [23] = {
        [1] = "Tol Dagor",
        [2] = "The Drain",
        [3] = "The Brig",
        [4] = "Detention Block",
        [5] = "Officer Quarters",
        [6] = "Overseer's Redoubt",
        [7] = "Overseer's Summit",
    },
    [24] = {
        [1] = "The Grand Foyer",
        [2] = "Upstairs",
        [3] = "The Cellar",
        [4] = "Catacombs",
        [5] = "The Rupture",
    },
}
function MethodDungeonTools:GetDungeonSublevels()
    return dungeonSubLevels
end

MethodDungeonTools.dungeonMaps = {
	[1] = {
		[0]= "BlackRookHoldDungeon",
		[1]= "BlackRookHoldDungeon1_",
		[2]= "BlackRookHoldDungeon2_",
		[3]= "BlackRookHoldDungeon3_",
		[4]= "BlackRookHoldDungeon4_",
		[5]= "BlackRookHoldDungeon5_",
		[6]= "BlackRookHoldDungeon6_",
	},
	[2] = {
		[0]= "TombofSargerasDungeon",
		[1]= "TombofSargerasDungeon1_",
		[2]= "TombofSargerasDungeon2_",
		[3]= "TombofSargerasDungeon3_",
		[4]= "TombofSargerasDungeon4_",
		[5]= "TombofSargerasDungeon5_",
	},
	[3] = {
		[0] = "SuramarNoblesDistrict",
		[1] = "SuramarNoblesDistrict",
		[2] = "SuramarNoblesDistrict1_",
		[3] = "SuramarNoblesDistrict2_",
	},
	[4] = {
		[0] = "DarkheartThicket",
		[1] = "DarkheartThicket",
	},
	[5] = {
		[0]= "AszunaDungeon",
		[1]= "AszunaDungeon",
	},
	[6] = {
		[0]= "Hallsofvalor",
		[1]= "Hallsofvalor1_",
		[2]= "Hallsofvalor",
		[3]= "Hallsofvalor2_",
	},

	[7] = {
		[0] = "HelheimDungeonDock",
		[1] = "HelheimDungeonDock",
		[2] = "HelheimDungeonDock1_",
		[3] = "HelheimDungeonDock2_",
	},
	[8] = {
		[0] = "NeltharionsLair",
		[1] = "NeltharionsLair",
	},
	[9] = {
		[0] = "LegionKarazhanDungeon",
		[1] = "LegionKarazhanDungeon6_",
		[2] = "LegionKarazhanDungeon5_",
		[3] = "LegionKarazhanDungeon4_",
		[4] = "LegionKarazhanDungeon3_",
		[5] = "LegionKarazhanDungeon2_",
		[6] = "LegionKarazhanDungeon1_",
	},
	[10] = {
		[0] = "LegionKarazhanDungeon",
		[1] = "LegionKarazhanDungeon7_",
		[2] = "LegionKarazhanDungeon8_",
		[3] = "LegionKarazhanDungeon9_",
		[4] = "LegionKarazhanDungeon10_",
		[5] = "LegionKarazhanDungeon11_",
		[6] = "LegionKarazhanDungeon12_",
		[7] = "LegionKarazhanDungeon13_",
		[8] = "LegionKarazhanDungeon14_",
	},
	[11] = {
		[0] = "ArgusDungeon",
		[1] = "ArgusDungeon",
	},
	[12] = {
		[0]= "SuamarCatacombsDungeon",
		[1]= "SuamarCatacombsDungeon1_",
	},
	[13] = {
		[0]= "VaultOfTheWardens",
		[1]= "VaultOfTheWardens1_",
		[2]= "VaultOfTheWardens2_",
		[3]= "VaultOfTheWardens3_",
	},
	[15] = {
		[0]= "CityOfGold",
		[1]= "CityOfGold1_",
		[2]= "CityOfGold2_",
	},
	[16] = {
		[0]= "KulTirasPirateTownDungeon",
		[1]= "KulTirasPirateTownDungeon",
	},
	[17] = {
        [0] = "KingsRest",
        [1] = "KingsRest1_"
	},
    [18] = {
        [0] = "ShrineOfTheStorm",
        [1] = "ShrineOfTheStorm",
        [2] = "ShrineOfTheStorm1_",
    },
    [19] = {
        [0] = "SiegeOfBoralus",
        [1] = "SiegeOfBoralus",
    },
    [20] = {
        [0] = "TempleOfSethralissA",
        [1] = "TempleOfSethralissA",
        [2] = "TempleOfSethralissB",
    },
    [21] = {
        [0] = "KezanDungeon",
        [1] = "KezanDungeon",
    },
    [22] = {
        [0] = "UnderrotExterior",
        [1] = "UnderrotExterior",
        [2] = "UnderrotInterior",
    },
    [23] = {
        [0] = "PrisonDungeon",
        [1] = "PrisonDungeon",
        [2] = "PrisonDungeon1_",
        [3] = "PrisonDungeon2_",
        [4] = "PrisonDungeon3_",
        [5] = "PrisonDungeon4_",
        [6] = "PrisonDungeon5_",
        [7] = "PrisonDungeon6_",
    },
    [24] = {
        [0] = "Waycrest",
        [1] = "Waycrest1_",
        [2] = "Waycrest2_",
        [3] = "Waycrest3_",
        [4] = "Waycrest4_",
        [5] = "Waycrest5_",
    },

}
MethodDungeonTools.dungeonBosses = {}
MethodDungeonTools.dungeonEnemies = {}
MethodDungeonTools.mapPOIs = {}

function MethodDungeonTools:GetDB()
    return db
end

function MethodDungeonTools:ShowInterface()
	if self.main_frame:IsShown() then
		MethodDungeonTools:HideInterface()
	else
		self.main_frame:Show();
		MethodDungeonTools:UpdateToDungeon(db.currentDungeonIdx)
		self.main_frame.HelpButton:Show()
	end
end

function MethodDungeonTools:HideInterface()
	self.main_frame:Hide();
	self.main_frame.HelpButton:Hide()
end

function MethodDungeonTools:ToggleDevMode()
    db.devMode = not db.devMode
    print(string.format("%sMDT|r: DevMode %s. Reload Interface!",methodColor,db.devMode and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
end


function MethodDungeonTools:CreateMenu()
	-- Close button
	self.main_frame.closeButton = CreateFrame("Button", "CloseButton", self.main_frame, "UIPanelCloseButton");
	self.main_frame.closeButton:ClearAllPoints()
	self.main_frame.closeButton:SetPoint("BOTTOMRIGHT", self.main_frame, "TOPRIGHT", 240, -2);
	self.main_frame.closeButton:SetScript("OnClick", function() MethodDungeonTools:HideInterface(); end)
	self.main_frame.closeButton:SetFrameLevel(4)
	--self.main_frame.closeButton:SetSize(32, h);#

	MethodDungeonTools:SkinCloseButton()

end

function MethodDungeonTools:SkinCloseButton()
	--attempt to skin close button for ElvUI
	if IsAddOnLoaded("ElvUI") then
	   local E, L, V, P, G = unpack(ElvUI)
	   local S
	   if E then S = E:GetModule("Skins") end
	   if S then
	      S:HandleCloseButton(MethodDungeonTools.main_frame.closeButton)
	   end
	end
end

function MethodDungeonTools:SkinProgressBar(progressBar)
    local bar = progressBar and progressBar.Bar
    if not bar then return end
    bar.Icon:Hide()
    bar.IconBG:Hide()
    if IsAddOnLoaded("ElvUI") then
        local E, L, V, P, G = unpack(ElvUI)
        if bar.BarFrame then bar.BarFrame:Hide() end
        if bar.BarFrame2 then bar.BarFrame2:Hide() end
        if bar.BarFrame3 then bar.BarFrame3:Hide() end
        if bar.BarGlow then bar.BarGlow:Hide() end
        if bar.Sheen then bar.Sheen:Hide() end
        if bar.IconBG then bar.IconBG:SetAlpha(0) end
        if bar.BorderLeft then bar.BorderLeft:SetAlpha(0) end
        if bar.BorderRight then bar.BorderRight:SetAlpha(0) end
        if bar.BorderMid then bar.BorderMid:SetAlpha(0) end
        bar:Height(18)
        bar:StripTextures()
        bar:CreateBackdrop("Transparent")
        bar:SetStatusBarTexture(E.media.normTex)
        local label = bar.Label
        if not label then return end
        label:ClearAllPoints()
        label:SetPoint("CENTER",bar,"CENTER")
    end
end


function MethodDungeonTools:MakeTopBottomTextures(frame)

    frame:SetMovable(true)

	if frame.topPanel == nil then
		frame.topPanel = CreateFrame("Frame", "MethodDungeonToolsTopPanel", frame)
		frame.topPanelTex = frame.topPanel:CreateTexture(nil, "BACKGROUND")
		frame.topPanelTex:SetAllPoints()
		frame.topPanelTex:SetDrawLayer(canvasDrawLayer, -5)
		frame.topPanelTex:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))

		frame.topPanelString = frame.topPanel:CreateFontString("MethodDungeonTools name")

		--use default font if ElvUI is enabled
		if IsAddOnLoaded("ElvUI") then
			frame.topPanelString:SetFontObject("GameFontNormalLarge")
			frame.topPanelString:SetFont(frame.topPanelString:GetFont(), 20)
		else
			frame.topPanelString:SetFont("Fonts\\FRIZQT__.TTF", 20)
		end



		frame.topPanelString:SetTextColor(1, 1, 1, 1)
		frame.topPanelString:SetJustifyH("CENTER")
		frame.topPanelString:SetJustifyV("CENTER")
		--frame.topPanelString:SetWidth(600)
		frame.topPanelString:SetHeight(20)
		frame.topPanelString:SetText("Method Dungeon Tools")
		frame.topPanelString:ClearAllPoints()
		frame.topPanelString:SetPoint("CENTER", frame.topPanel, "CENTER", 0, 0)
		frame.topPanelString:Show()

		frame.topPanelLogo = frame.topPanel:CreateTexture(nil, "HIGH", nil, 7)
		frame.topPanelLogo:SetTexture("Interface\\AddOns\\MethodDungeonTools\\Textures\\Method")
		frame.topPanelLogo:SetWidth(24)
		frame.topPanelLogo:SetHeight(24)
		frame.topPanelLogo:SetPoint("RIGHT",frame.topPanelString,"LEFT",-5,0)
		frame.topPanelLogo:Show()

	end

    frame.topPanel:ClearAllPoints()
    frame.topPanel:SetSize(frame:GetWidth(), 30)
    frame.topPanel:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)

    frame.topPanel:EnableMouse(true)
    frame.topPanel:RegisterForDrag("LeftButton")
    frame.topPanel:SetScript("OnDragStart", function(self,button)
        frame:SetMovable(true)
        frame:StartMoving()
    end)
    frame.topPanel:SetScript("OnDragStop", function(self,button)
        frame:StopMovingOrSizing();
        frame:SetMovable(false);
        local from,_,to,x,y = MethodDungeonTools.main_frame:GetPoint()
        db.anchorFrom = from
        db.anchorTo = to
        db.xoffset,db.yoffset = x,y
    end)

    if frame.bottomPanel == nil then
        frame.bottomPanel = CreateFrame("Frame", "MethodDungeonToolsBottomPanel", frame)
        frame.bottomPanelTex = frame.bottomPanel:CreateTexture(nil, "BACKGROUND")
        frame.bottomPanelTex:SetAllPoints()
        frame.bottomPanelTex:SetDrawLayer(canvasDrawLayer, -5)
        frame.bottomPanelTex:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))

    end

    frame.bottomPanel:ClearAllPoints()
    frame.bottomPanel:SetSize(frame:GetWidth(), 30)
    frame.bottomPanel:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)

    frame.bottomPanelString = frame.topPanel:CreateFontString("MethodDungeonTools Version")
    frame.bottomPanelString:SetFontObject("GameFontNormalSmall")
    frame.bottomPanelString:SetJustifyH("CENTER")
	frame.bottomPanelString:SetJustifyV("CENTER")
	frame.bottomPanelString:SetText("v"..GetAddOnMetadata(AddonName, "Version"))
	frame.bottomPanelString:SetPoint("CENTER", frame.bottomPanel, "CENTER", 0, 0)
	frame.bottomPanelString:SetTextColor(1, 1, 1, 1)
	frame.bottomPanelString:Show()


	frame.bottomPanel:EnableMouse(true)
	frame.bottomPanel:RegisterForDrag("LeftButton")
	frame.bottomPanel:SetScript("OnDragStart", function(self,button)
		frame:SetMovable(true)
        frame:StartMoving()
    end)
	frame.bottomPanel:SetScript("OnDragStop", function(self,button)
        frame:StopMovingOrSizing()
		frame:SetMovable(false)
		local from,_,to,x,y = MethodDungeonTools.main_frame:GetPoint()
		db.anchorFrom = from
		db.anchorTo = to
		db.xoffset,db.yoffset = x,y
    end)

end

function MethodDungeonTools:MakeSidePanel(frame)

	if frame.sidePanel == nil then
		frame.sidePanel = CreateFrame("Frame", "MethodDungeonToolsSidePanel", frame)
		frame.sidePanelTex = frame.sidePanel:CreateTexture(nil, "BACKGROUND")
		frame.sidePanelTex:SetAllPoints()
		frame.sidePanelTex:SetDrawLayer(canvasDrawLayer, -5)
		frame.sidePanelTex:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))
		frame.sidePanelTex:Show()
	end


	frame.sidePanel:ClearAllPoints();
	frame.sidePanel:SetSize(250, frame:GetHeight()+(frame.topPanel:GetHeight()*2))
	frame.sidePanel:SetPoint("TOPLEFT", frame.topPanel, "TOPRIGHT", -1, 0)

	frame.sidePanelString = frame.sidePanel:CreateFontString("MethodDungeonToolsSidePanelText")
	frame.sidePanelString:SetFont("Fonts\\FRIZQT__.TTF", 10)
	frame.sidePanelString:SetTextColor(1, 1, 1, 1);
	frame.sidePanelString:SetJustifyH("LEFT")
	frame.sidePanelString:SetJustifyV("TOP")
	frame.sidePanelString:SetWidth(200)
	frame.sidePanelString:SetHeight(500)
	frame.sidePanelString:SetText("");
	frame.sidePanelString:ClearAllPoints();
	frame.sidePanelString:SetPoint("TOPLEFT", frame.sidePanel, "TOPLEFT", 33, -120-30-25);
	frame.sidePanelString:Hide();



	frame.sidePanel.WidgetGroup = AceGUI:Create("SimpleGroup")
	frame.sidePanel.WidgetGroup:SetWidth(245);
	frame.sidePanel.WidgetGroup:SetHeight(frame:GetHeight()+(frame.topPanel:GetHeight()*2)-31);
	frame.sidePanel.WidgetGroup:SetPoint("TOP",frame.sidePanel,"TOP",3,-1)
	frame.sidePanel.WidgetGroup:SetLayout("Flow")

	frame.sidePanel.WidgetGroup.frame:SetFrameStrata(mainFrameStrata)
	frame.sidePanel.WidgetGroup.frame:SetBackdropColor(1,1,1,0)
	frame.sidePanel.WidgetGroup.frame:Hide()

	--dirty hook to make widgetgroup show/hide
	local originalShow,originalHide = frame.Show,frame.Hide
	function frame:Show(...)
		frame.sidePanel.WidgetGroup.frame:Show()
		return originalShow(self, ...);
	end
	function frame:Hide(...)
		frame.sidePanel.WidgetGroup.frame:Hide()
        MethodDungeonTools.pullTooltip:Hide()
		return originalHide(self, ...);
	end

	--preset selection
	frame.sidePanel.WidgetGroup.PresetDropDown = AceGUI:Create("Dropdown")
	local dropdown = frame.sidePanel.WidgetGroup.PresetDropDown
	dropdown.text:SetJustifyH("LEFT")
	dropdown:SetCallback("OnValueChanged",function(widget,callbackName,key)
		if db.presets[db.currentDungeonIdx][key].value==0 then
			MethodDungeonTools:OpenNewPresetDialog()
			MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(true)
		else
			if key == 1 then
				MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(true)
			else
				MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
			end
			db.currentPreset[db.currentDungeonIdx] = key
			MethodDungeonTools:UpdateMap()
		end
	end)
	MethodDungeonTools:UpdatePresetDropDown()
	frame.sidePanel.WidgetGroup:AddChild(dropdown)


	---new profile,rename,export,delete
	local buttonWidth = 80
	frame.sidePanelNewButton = AceGUI:Create("Button")
	frame.sidePanelNewButton:SetText("New")
	frame.sidePanelNewButton:SetWidth(buttonWidth)
	--button fontInstance
	local fontInstance = CreateFont("MDTButtonFont");
	fontInstance:CopyFontObject(frame.sidePanelNewButton.frame:GetNormalFontObject());
	local fontName,height = fontInstance:GetFont()
	fontInstance:SetFont(fontName,10)
	frame.sidePanelNewButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelNewButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelNewButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelNewButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:OpenNewPresetDialog()
	end)

	frame.sidePanelRenameButton = AceGUI:Create("Button")
	frame.sidePanelRenameButton:SetWidth(buttonWidth)
	frame.sidePanelRenameButton:SetText("Rename")
	frame.sidePanelRenameButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelRenameButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelRenameButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelRenameButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:HideAllDialogs()
		local currentPresetName = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text
		MethodDungeonTools.main_frame.RenameFrame:Show()
		MethodDungeonTools.main_frame.RenameFrame.RenameButton:SetDisabled(true)
		MethodDungeonTools.main_frame.RenameFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
		MethodDungeonTools.main_frame.RenameFrame.Editbox:SetText(currentPresetName)
		MethodDungeonTools.main_frame.RenameFrame.Editbox:HighlightText(0, string.len(currentPresetName))
		MethodDungeonTools.main_frame.RenameFrame.Editbox:SetFocus()
	end)

	frame.sidePanelImportButton = AceGUI:Create("Button")
	frame.sidePanelImportButton:SetText("Import")
	frame.sidePanelImportButton:SetWidth(buttonWidth)
	frame.sidePanelImportButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelImportButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelImportButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelImportButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:OpenImportPresetDialog()
	end)

	frame.sidePanelExportButton = AceGUI:Create("Button")
	frame.sidePanelExportButton:SetText("Export")
	frame.sidePanelExportButton:SetWidth(buttonWidth)
	frame.sidePanelExportButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelExportButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelExportButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelExportButton:SetCallback("OnClick",function(widget,callbackName,value)
		local export = MethodDungeonTools:TableToString(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]],true)
		MethodDungeonTools:HideAllDialogs()
		MethodDungeonTools.main_frame.ExportFrame:Show()
		MethodDungeonTools.main_frame.ExportFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
		MethodDungeonTools.main_frame.ExportFrameEditbox:SetText(export)
		MethodDungeonTools.main_frame.ExportFrameEditbox:HighlightText(0, string.len(export))
		MethodDungeonTools.main_frame.ExportFrameEditbox:SetFocus()
	end)

	frame.sidePanelDeleteButton = AceGUI:Create("Button")
	frame.sidePanelDeleteButton:SetText("Delete")
	frame.sidePanelDeleteButton:SetWidth(buttonWidth)
	frame.sidePanelDeleteButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelDeleteButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelDeleteButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelDeleteButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:HideAllDialogs()
		frame.DeleteConfirmationFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
		local currentPresetName = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text
		frame.DeleteConfirmationFrame.label:SetText("Delete "..currentPresetName.."?")
		frame.DeleteConfirmationFrame:Show()
	end)

	frame.sidePanelClearButton = AceGUI:Create("Button")
	frame.sidePanelClearButton:SetText("Clear")
	frame.sidePanelClearButton:SetWidth(buttonWidth)
	frame.sidePanelClearButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelClearButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelClearButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelClearButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:HideAllDialogs()
		frame.ClearConfirmationFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
		local currentPresetName = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text
		frame.ClearConfirmationFrame.label:SetText("Clear "..currentPresetName.."?")
		frame.ClearConfirmationFrame:Show()
	end)

	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelNewButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelImportButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelExportButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelRenameButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelClearButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelDeleteButton)


	--Tyranical/Fortified toggle
	frame.sidePanelFortifiedCheckBox = AceGUI:Create("CheckBox")
	frame.sidePanelFortifiedCheckBox:SetLabel("Fort")
	frame.sidePanelFortifiedCheckBox.text:SetTextHeight(10)
	frame.sidePanelFortifiedCheckBox:SetWidth(65)
	frame.sidePanelFortifiedCheckBox:SetHeight(15)
	if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix then
		if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix == "fortified" then frame.sidePanelFortifiedCheckBox:SetValue(true) end
	end
	frame.sidePanelFortifiedCheckBox:SetImage("Interface\\ICONS\\ability_toughness")
	frame.sidePanelFortifiedCheckBox:SetCallback("OnValueChanged",function(widget,callbackName,value)
		if value == true then
			db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix = "fortified"
		elseif value == false then
			db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix = "tyrannical"
		end
		frame.sidePanelTyrannicalCheckBox:SetValue(not value)
	end)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelFortifiedCheckBox)


	frame.sidePanelTyrannicalCheckBox = AceGUI:Create("CheckBox")
	frame.sidePanelTyrannicalCheckBox:SetLabel("Tyran")
	frame.sidePanelTyrannicalCheckBox.text:SetTextHeight(10)
	frame.sidePanelTyrannicalCheckBox:SetWidth(74)
	frame.sidePanelTyrannicalCheckBox:SetHeight(15)
	if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix then
		if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix == "tyrannical" then frame.sidePanelTyrannicalCheckBox:SetValue(true) end
	end
	frame.sidePanelTyrannicalCheckBox:SetImage("Interface\\ICONS\\achievement_boss_archaedas")
	frame.sidePanelTyrannicalCheckBox:SetCallback("OnValueChanged",function(widget,callbackName,value)
		if value == true then
			db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix = "tyrannical"
		elseif value == false then
			db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix = "fortified"
		end
		frame.sidePanelFortifiedCheckBox:SetValue(not value)
	end)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelTyrannicalCheckBox)

	frame.sidePanelTeemingCheckBox = AceGUI:Create("CheckBox")
	frame.sidePanelTeemingCheckBox:SetLabel("Teeming")
	frame.sidePanelTeemingCheckBox.text:SetTextHeight(10)
	frame.sidePanelTeemingCheckBox:SetWidth(90)
	frame.sidePanelTeemingCheckBox:SetHeight(15)
	frame.sidePanelTeemingCheckBox:SetDisabled(false)

	if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming then
		if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming == true then frame.sidePanelTeemingCheckBox:SetValue(true) end
	end
	frame.sidePanelTeemingCheckBox:SetImage("Interface\\ICONS\\spell_nature_massteleport")
	frame.sidePanelTeemingCheckBox:SetCallback("OnValueChanged",function(widget,callbackName,value)
		db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming = value
		MethodDungeonTools:UpdateMap()
        MethodDungeonTools:ReloadPullButtons()
	end)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelTeemingCheckBox)

	--Difficulty Selection
	frame.sidePanel.DifficultySliderLabel = AceGUI:Create("Label")
	frame.sidePanel.DifficultySliderLabel:SetText(" Level: ")
	frame.sidePanel.DifficultySliderLabel:SetWidth(35)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanel.DifficultySliderLabel)


	frame.sidePanel.DifficultySlider = AceGUI:Create("Slider")
	frame.sidePanel.DifficultySlider:SetSliderValues(1,35,1)
	frame.sidePanel.DifficultySlider:SetWidth(195)	--240
	frame.sidePanel.DifficultySlider:SetValue(db.currentDifficulty)
	frame.sidePanel.DifficultySlider:SetCallback("OnValueChanged",function(widget,callbackName,value)
		local difficulty = tonumber(value)
		db.currentDifficulty = difficulty or db.currentDifficulty
	end)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanel.DifficultySlider)

	frame.sidePanel.middleLine = AceGUI:Create("Heading")
	frame.sidePanel.middleLine:SetWidth(240)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanel.middleLine)
    frame.sidePanel.WidgetGroup.frame:SetFrameLevel(3)

	--progress bar


	frame.sidePanel.ProgressBar = CreateFrame("Frame", nil, frame.sidePanel, "ScenarioTrackerProgressBarTemplate")
	frame.sidePanel.ProgressBar:Show()
	frame.sidePanel.ProgressBar:SetPoint("TOP",frame.sidePanel.WidgetGroup.frame,"BOTTOM",-10,5)
	MethodDungeonTools:Progressbar_SetValue(frame.sidePanel.ProgressBar, 50,205,205)
    MethodDungeonTools:SkinProgressBar(frame.sidePanel.ProgressBar)
end

function MethodDungeonTools:UpdatePresetDropDown()
	local dropdown = MethodDungeonTools.main_frame.sidePanel.WidgetGroup.PresetDropDown
	local presetList = {}
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		table.insert(presetList,k,v.text)
	end
	dropdown:SetList(presetList)
	dropdown:SetValue(db.currentPreset[db.currentDungeonIdx])
end


---FormatEnemyForces
function MethodDungeonTools:FormatEnemyForces(forces,forcesmax,progressbar)
    if not forcesmax then forcesmax = MethodDungeonTools:IsCurrentPresetTeeming() and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal end
    if db.enemyForcesFormat == 1 then
        if progressbar then return forces.."/"..forcesmax end
        return forces
    elseif db.enemyForcesFormat == 2 then
        if progressbar then return string.format((forces.."/"..forcesmax.." (%.1f%%)"),(forces/forcesmax)*100) end
        return string.format(forces.." (%.1f%%)",(forces/forcesmax)*100)
    end
end

---Progressbar_SetValue
---Sets the value/progress/color of the count progressbar to the apropriate data
function MethodDungeonTools:Progressbar_SetValue(self, pullCurrent,totalCurrent,totalMax)
	local percent = (totalCurrent/totalMax)*100
	if percent >= 102 then
		if totalCurrent-totalMax > 8 then
			self.Bar:SetStatusBarColor(1,0,0,1)
		else
			self.Bar:SetStatusBarColor(0,1,0,1)
		end
    elseif percent >= 100 then
        self.Bar:SetStatusBarColor(0,1,0,1)
	else
		self.Bar:SetStatusBarColor(0.26,0.42,1)
	end
	self.Bar:SetValue(percent);
	self.Bar.Label:SetText(pullCurrent.." - "..MethodDungeonTools:FormatEnemyForces(totalCurrent,totalMax,true));
	self.AnimValue = percent;
end

function MethodDungeonTools:OnPan(cursorX, cursorY)
	local scrollFrame = MethodDungeonToolsScrollFrame
    local scale = MethodDungeonToolsMapPanelFrame:GetScale()/1.5
	local deltaX = (scrollFrame.cursorX - cursorX)/scale
	local deltaY = (cursorY - scrollFrame.cursorY)/scale
	if(abs(deltaX) >= 1 or abs(deltaY) >= 1)then
		local newHorizontalPosition = max(0, deltaX + scrollFrame:GetHorizontalScroll());
		newHorizontalPosition = min(newHorizontalPosition, scrollFrame.maxX);
		local newVerticalPosition = max(0, deltaY + scrollFrame:GetVerticalScroll());
		newVerticalPosition = min(newVerticalPosition, scrollFrame.maxY);
		scrollFrame:SetHorizontalScroll(newHorizontalPosition)
		scrollFrame:SetVerticalScroll(newVerticalPosition)
		scrollFrame.cursorX = cursorX
		scrollFrame.cursorY = cursorY
	end
end

--Update list of selected Enemies shown in side panel
function MethodDungeonTools:UpdateEnemiesSelected()
	local teeming = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
	local preset = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
	table.wipe(dungeonEnemiesSelected)


	for enemyIdx,clones in pairs(preset.value.pulls[preset.value.currentPull]) do
		for k,cloneIdx in pairs(clones) do
			local enemyName = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["name"]
			local count = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["count"]
			if not dungeonEnemiesSelected[enemyName] then dungeonEnemiesSelected[enemyName] = {} end
			dungeonEnemiesSelected[enemyName].count = count
			dungeonEnemiesSelected[enemyName].quantity = dungeonEnemiesSelected[enemyName].quantity or 0
			dungeonEnemiesSelected[enemyName].quantity = dungeonEnemiesSelected[enemyName].quantity + 1
		end
	end

	local sidePanelStringText = ""
	local newLineString = ""
	local currentTotalCount = 0
	for enemyName,v in pairs(dungeonEnemiesSelected) do
		sidePanelStringText = sidePanelStringText..newLineString..v.quantity.."x "..enemyName.."("..v.count*v.quantity..")"
		newLineString = "\n"
		currentTotalCount = currentTotalCount + (v.count*v.quantity)
	end
	sidePanelStringText = sidePanelStringText..newLineString..newLineString.."Count: "..currentTotalCount
	self.main_frame.sidePanelString:SetText(sidePanelStringText)

	local grandTotal = 0
	for pullIdx,pull in pairs(preset.value.pulls) do
		for enemyIdx,clones in pairs(pull) do
			for k,v in pairs(clones) do
                if not MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][v] then
                    clones[v] = nil
                else
                    local isCloneTeeming = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][v].teeming
                    if teeming == true or ((isCloneTeeming and isCloneTeeming == false) or (not isCloneTeeming)) then
                        grandTotal = grandTotal + MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx].count
                    end
                end
			end
		end
	end
	--count up to and including the currently selected pull
	local pullCurrent = 0
	for pullIdx,pull in pairs(preset.value.pulls) do
		if pullIdx <= db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull then
			for enemyIdx,clones in pairs(pull) do
				for k,v in pairs(clones) do
                    if not MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][v] then
                        clones[v] = nil
                    else
                        local isCloneTeeming = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][v].teeming
                        if teeming == true or ((isCloneTeeming and isCloneTeeming == false) or (not isCloneTeeming)) then
                            pullCurrent = pullCurrent + MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx].count
                        end
                    end
				end
			end
		else
			break
		end
	end
	MethodDungeonTools:Progressbar_SetValue(MethodDungeonTools.main_frame.sidePanel.ProgressBar, pullCurrent,grandTotal,teeming==true and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal)


end

function MethodDungeonTools:AddOrRemoveEnemyBlipToCurrentPull(i,add,ignoreGrouped)
	local pull = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull
	local preset = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
	preset.value.pulls = preset.value.pulls or {}
	preset.value.pulls[pull] = preset.value.pulls[pull] or {}
	preset.value.pulls[pull][dungeonEnemyBlips[i].enemyIdx] = preset.value.pulls[pull][dungeonEnemyBlips[i].enemyIdx] or {}
	if add == true then
		local found = false
		for k,v in pairs(preset.value.pulls[pull][dungeonEnemyBlips[i].enemyIdx]) do
			if v == dungeonEnemyBlips[i].cloneIdx then found = true end
		end
		if found==false then tinsert(preset.value.pulls[pull][dungeonEnemyBlips[i].enemyIdx],dungeonEnemyBlips[i].cloneIdx) end
		--make sure this pull is the only one that contains this npc clone (no double dipping)
		for pullIdx,p in pairs(preset.value.pulls) do
			if pullIdx ~= pull and p[dungeonEnemyBlips[i].enemyIdx] then
				for k,v in pairs(p[dungeonEnemyBlips[i].enemyIdx]) do
					if v == dungeonEnemyBlips[i].cloneIdx then
						tremove(preset.value.pulls[pullIdx][dungeonEnemyBlips[i].enemyIdx],k)
                        MethodDungeonTools:UpdatePullButtonNPCData(pullIdx)
						--print("Removing "..dungeonEnemyBlips[i].name.." "..dungeonEnemyBlips[i].cloneIdx.." from pull"..pullIdx)
					end
				end
			end
		end
	elseif add == false then
		for k,v in pairs(preset.value.pulls[pull][dungeonEnemyBlips[i].enemyIdx]) do
			if v == dungeonEnemyBlips[i].cloneIdx then tremove(preset.value.pulls[pull][dungeonEnemyBlips[i].enemyIdx],k) end
		end
	end
	--linked npcs
	if not ignoreGrouped then
		for idx=1,numDungeonEnemyBlips do
			if dungeonEnemyBlips[i].g and dungeonEnemyBlips[idx].g == dungeonEnemyBlips[i].g and i~=idx then
				MethodDungeonTools:AddOrRemoveEnemyBlipToCurrentPull(idx,add,true)
			end
		end
	end
	MethodDungeonTools:UpdatePullButtonNPCData(pull)
end

---UpdateEnemyBlipSelection
---Colors blips green when they are selected
function MethodDungeonTools:UpdateEnemyBlipSelection(i, forceDeselect, ignoreLinked, otherPull)

    if dungeonEnemyBlips[i]:IsShown() then
        if otherPull and otherPull == true then
            dungeonEnemyBlips[i].border:SetVertexColor(unpack(selectedGreen))
            dungeonEnemyBlips[i].highlight2:Show()
        else
            if forceDeselect and forceDeselect == true then
                dungeonEnemyBlips[i].selected = false
            else
                dungeonEnemyBlips[i].selected = not dungeonEnemyBlips[i].selected
            end
            if dungeonEnemyBlips[i].selected == true then
                dungeonEnemyBlips[i].border:SetVertexColor(unpack(selectedGreen))
                dungeonEnemyBlips[i].highlight2:Show()
                dungeonEnemyBlips[i].highlight3:Show()
            else
                local r,g,b,a = dungeonEnemyBlips[i].color.r,dungeonEnemyBlips[i].color.g,dungeonEnemyBlips[i].color.b,dungeonEnemyBlips[i].color.a
                dungeonEnemyBlips[i].border:SetVertexColor(r,g,b,a)
                dungeonEnemyBlips[i].highlight2:Hide()
                dungeonEnemyBlips[i].highlight3:Hide()
            end
            --select/deselect linked npcs
            if not ignoreLinked then
                for idx=1,numDungeonEnemyBlips do
                    if dungeonEnemyBlips[i].g and dungeonEnemyBlips[idx].g == dungeonEnemyBlips[i].g and i~=idx then
                        if dungeonEnemyBlips[idx]:IsShown() then
                            if forceDeselect and forceDeselect == true then
                                dungeonEnemyBlips[idx].selected = false
                            else
                                dungeonEnemyBlips[idx].selected = dungeonEnemyBlips[i].selected
                            end
                            if dungeonEnemyBlips[idx].selected == true then
                                dungeonEnemyBlips[idx].border:SetVertexColor(unpack(selectedGreen))
                                dungeonEnemyBlips[idx].highlight2:Show()
                                dungeonEnemyBlips[idx].highlight3:Show()
                            else
                                local r,g,b,a = dungeonEnemyBlips[idx].color.r,dungeonEnemyBlips[idx].color.g,dungeonEnemyBlips[idx].color.b,dungeonEnemyBlips[idx].color.a
                                dungeonEnemyBlips[idx].border:SetVertexColor(r,g,b,a)
                                dungeonEnemyBlips[idx].highlight2:Hide()
                                dungeonEnemyBlips[idx].highlight3:Hide()
                            end
                        else
                            dungeonEnemyBlips[idx].highlight2:Hide()
                            dungeonEnemyBlips[idx].highlight3:Hide()
                        end
                    end
                end
            end
        end

    else
        dungeonEnemyBlips[i].highlight2:Hide()
        dungeonEnemyBlips[i].highlight3:Hide()
    end

end

local lastModelId
local cloneOffset = 0

function MethodDungeonTools:ZoomMap(delta,resetZoom)
	local scrollFrame = MethodDungeonToolsScrollFrame;
	local oldScrollH = scrollFrame:GetHorizontalScroll();
	local oldScrollV = scrollFrame:GetVerticalScroll();

	local mainFrame = MethodDungeonToolsMapPanelFrame

	local oldScale = mainFrame:GetScale();
	local newScale = oldScale + delta * 0.3;

	newScale = max(1, newScale);
	newScale = min(15, newScale);
	if resetZoom then newScale = 1 end

	mainFrame:SetScale(newScale)

	local scaledSizeX = mainFrame:GetWidth() * newScale
	local scaledSizeY = mainFrame:GetHeight() * newScale

	scrollFrame.maxX = (scaledSizeX - mainFrame:GetWidth()) / newScale
	scrollFrame.maxY = (scaledSizeY - mainFrame:GetHeight()) / newScale
	scrollFrame.zoomedIn = abs(newScale - 1) > 0.02

	local cursorX,cursorY = GetCursorPosition()
	local frameX = (cursorX / UIParent:GetScale()) - scrollFrame:GetLeft();
	local frameY = scrollFrame:GetTop() - (cursorY / UIParent:GetScale());

	local scaleChange = newScale / oldScale
	local newScrollH =  (scaleChange * frameX - frameX) / newScale + oldScrollH
	local newScrollV =  (scaleChange * frameY - frameY) / newScale + oldScrollV

	newScrollH = min(newScrollH, scrollFrame.maxX);
	newScrollH = max(0, newScrollH);
	newScrollV = min(newScrollV, scrollFrame.maxY);
	newScrollV = max(0, newScrollV);

	scrollFrame:SetHorizontalScroll(newScrollH);
	scrollFrame:SetVerticalScroll(newScrollV);

end

---ActivatePullTooltip
---
function MethodDungeonTools:ActivatePullTooltip(pull)
    local pullTooltip = MethodDungeonTools.pullTooltip

    pullTooltip.currentPull = pull
    pullTooltip:Show()
end

---UpdatePullTooltip
---Updates the tooltip which is being displayed when a pull is mouseovered
function MethodDungeonTools:UpdatePullTooltip(tooltip)
    local frame = MethodDungeonTools.main_frame
	if not MouseIsOver(frame.sidePanel.pullButtonsScrollFrame.frame) then
        tooltip:Hide()
    elseif MouseIsOver(frame.sidePanel.newPullButton.frame) then
        tooltip:Hide()
	else
		if frame.sidePanel.newPullButtons and tooltip.currentPull and frame.sidePanel.newPullButtons[tooltip.currentPull] then
			for k,v in pairs(frame.sidePanel.newPullButtons[tooltip.currentPull].enemyPortraits) do
				if MouseIsOver(v) then
					if v:IsShown() then
                        --model
						if v.enemyData.displayId and (not tooltip.modelNpcId or (tooltip.modelNpcId ~= v.enemyData.displayId)) then
							tooltip.Model:SetDisplayInfo(v.enemyData.displayId)
							tooltip.modelNpcId = v.enemyData.displayId
						end
						tooltip.Model:Show()
                        --topString
                        local newLine = "\n"
                        local text = newLine..newLine..newLine..v.enemyData.name.." x"..v.enemyData.quantity..newLine
                        text = text.."Level "..v.enemyData.level.." "..v.enemyData.creatureType..newLine
                        --ViragDevTool_AddData(v.enemyData)
                        local fortified = false
                        local boss = false
                        if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix then
                            if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix == "fortified" then fortified = true end
                        end
                        local tyrannical = not fortified
                        local health = MethodDungeonTools:CalculateEnemyHealth(boss,fortified,tyrannical,v.enemyData.baseHealth,db.currentDifficulty)
                        text = text..MethodDungeonTools:FormatEnemyHealth(health).." HP"..newLine

                        local totalForcesMax = MethodDungeonTools:IsCurrentPresetTeeming() and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal
                        text = text.."Enemy Forces: "..MethodDungeonTools:FormatEnemyForces(v.enemyData.count,totalForcesMax,false)

                        tooltip.topString:SetText(text)
                        tooltip.topString:Show()

					else
                        --model
						tooltip.Model:Hide()
                        --topString
                        tooltip.topString:Hide()
					end
					break;
				end
			end
            local countEnemies = 0
            for k,v in pairs(frame.sidePanel.newPullButtons[tooltip.currentPull].enemyPortraits) do
                if v:IsShown() then countEnemies = countEnemies + 1 end
            end
            if countEnemies == 0 then
                tooltip:Hide()
                return
            end
            local pullForces = MethodDungeonTools:CountForces(tooltip.currentPull,true)
            local totalForces = MethodDungeonTools:CountForces(tooltip.currentPull,false)
            local totalForcesMax = MethodDungeonTools:IsCurrentPresetTeeming() and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal
            local text = string.format(MethodDungeonTools.pullTooltip.botString.defaultText,pullForces,totalForces,totalForcesMax)

            local text = "Enemy Forces: "..MethodDungeonTools:FormatEnemyForces(pullForces,totalForcesMax,false)
            text = text.. "\nTotal :"..MethodDungeonTools:FormatEnemyForces(totalForces,totalForcesMax,true)

            tooltip.botString:SetText(text)
            tooltip.botString:Show()
		end
	end
end

---CountForces
---Counts total selected enemy forces in the current preset up to pull
function MethodDungeonTools:CountForces(currentPull,currentOnly)
    --count up to and including the currently selected pull
    local preset = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
    local pullCurrent = 0
    for pullIdx,pull in pairs(preset.value.pulls) do
        if not currentOnly or (currentOnly and pullIdx == currentPull) then
            if pullIdx <= currentPull then
                for enemyIdx,clones in pairs(pull) do
                    for k,v in pairs(clones) do
                        local isCloneTeeming = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][v].teeming
                        if MethodDungeonTools:IsCurrentPresetTeeming() or ((isCloneTeeming and isCloneTeeming == false) or (not isCloneTeeming)) then
                            pullCurrent = pullCurrent + MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx].count
                        end
                    end
                end
            else
                break
            end
        end
    end
    return pullCurrent
end

---IsCurrentPresetTeeming
---Returns true if the current preset has teeming turned on, false otherwise
function MethodDungeonTools:IsCurrentPresetTeeming()
    return db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
end


local currentBlip
local currentWaypoints
local currentWaypointBlip
function MethodDungeonTools:GetCurrentDevmodeBlip()
    for blipIdx,blip in pairs(dungeonEnemyBlips) do
        if blip.devSelected then
            return blip
        end
    end
end

function MethodDungeonTools:SetCurrentDevmodeBlip(enemyIdx,cloneIdx)
    for blipIdx,blip in pairs(dungeonEnemyBlips) do
        if blip.enemyIdx == enemyIdx and blip.cloneIdx == cloneIdx then
            blip.devSelected = true
        else
            blip.devSelected = nil
        end
    end
end

local moverFrame = CreateFrame("Frame")
local blipMoverFrame = CreateFrame("Frame")
---MethodDungeonTools.OnMouseDown
---Handles mouse-down events on the map scrollframe
MethodDungeonTools.OnMouseDown = function(self,button)
	local scrollFrame = MethodDungeonTools.main_frame.scrollFrame
    if db.devMode then
        if button == "LeftButton" then

            for blipIdx,blip in pairs(dungeonEnemyBlips) do
                --drag blips
                local blipFound
                if MouseIsOver(blip) then
                    local startx,starty = MethodDungeonTools:GetCursorPosition()
                    currentBlip = blip
                    blipMoverFrame.isMoving = true
                    blipMoverFrame:SetScript("OnUpdate", function(self, tick)
                        if not MouseIsOver(MethodDungeonToolsScrollFrame) then return end
                        local x,y = MethodDungeonTools:GetCursorPosition()
                        blip:SetPoint("CENTER",MethodDungeonTools.main_frame.mapPanelTile1,"TOPLEFT",x,y)
                        blip.x = x
                        blip.y = y
                        startx,starty = MethodDungeonTools:GetCursorPosition()
                    end)
                    blipFound = true
                end
                --drag patrol pathway
                if blip.patrol then
                    local found
                    for idx,waypoint in pairs(blip.patrol) do
                        if MouseIsOver(waypoint) and waypoint:IsShown() then
                            found = true
                            local startx,starty = MethodDungeonTools:GetCursorPosition()
                            currentWaypoints = currentWaypoints or {}
                            tinsert(currentWaypoints,waypoint)
                            waypoint.index = idx
                            currentWaypointBlip = blip
                            moverFrame.isMoving = true
                            moverFrame:SetScript("OnUpdate", function(self, tick)
                                if not MouseIsOver(MethodDungeonToolsScrollFrame) then return end
                                local x,y = MethodDungeonTools:GetCursorPosition()
                                for _,waypoint in pairs(currentWaypoints) do
                                    waypoint:SetPoint("CENTER",MethodDungeonTools.main_frame.mapPanelTile1,"TOPLEFT",x,y)
                                    waypoint.x = x
                                    waypoint.y = y
                                end
                                startx,starty = MethodDungeonTools:GetCursorPosition()
                            end)
                        end
                    end
                    if found then return end
                end
                if blipFound then return end
            end

        end
        if button == "RightButton" then
            if moverFrame.isMoving then return end
            for blipIdx,blip in pairs(dungeonEnemyBlips) do
                if MouseIsOver(blip) then
                    currentBlip = blip
                    if IsAltKeyDown() then
                        tremove(MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][currentBlip.enemyIdx].clones,currentBlip.cloneIdx)
                        MethodDungeonTools:UpdateMap()
                    end
                    return
                end
            end
            return
        end

        if IsAltKeyDown() then return end
    end
	if ( button == "LeftButton" and scrollFrame.zoomedIn ) then
		scrollFrame.panning = true;
		scrollFrame.cursorX,scrollFrame.cursorY = GetCursorPosition()
	end
end

--local here to be used for dev context menu
local cursorX, cursorY
---MethodDungeonTools.OnMouseUp
---handles mouse-up events on the map scrollframe
MethodDungeonTools.OnMouseUp = function(self,button)
	local scrollFrame = MethodDungeonTools.main_frame.scrollFrame
	local frame = MethodDungeonTools.main_frame
	if ( button == "LeftButton") then
		frame.contextDropdown:Hide()
		if scrollFrame.panning then scrollFrame.panning = false end

        --end dragging blip
        if db.devMode then
            blipMoverFrame:SetScript("OnUpdate",nil)
            blipMoverFrame.isMoving = nil
            moverFrame:SetScript("OnUpdate",nil)
            moverFrame.isMoving = nil
            if currentBlip then
                local cloneData = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][currentBlip.enemyIdx].clones[currentBlip.cloneIdx]
                if cloneData and currentBlip.x and currentBlip.y then
                    cloneData.x = currentBlip.x
                    cloneData.y = currentBlip.y
                    if cloneData.patrol and cloneData.patrol[1] then
                        cloneData.patrol[1] = {x=cloneData.x,y=cloneData.y}
                    end
                end
            end
            if currentWaypoints then
                for _,currentWaypoint in pairs(currentWaypoints) do
                    local cloneData = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][currentWaypointBlip.enemyIdx].clones[currentWaypointBlip.cloneIdx]
                    if cloneData and cloneData.patrol and cloneData.patrol[currentWaypoint.index]then
                        cloneData.patrol[currentWaypoint.index].x = currentWaypoint.x
                        cloneData.patrol[currentWaypoint.index].y = currentWaypoint.y
                    end
                end
            end
            currentWaypoints = nil
            currentBlip = nil
            MethodDungeonTools:UpdateMap()
            return
        end

		--handle clicks on enemy blips
		if MouseIsOver(MethodDungeonToolsScrollFrame) then
			for i=1,numDungeonEnemyBlips do
				if MouseIsOver(dungeonEnemyBlips[i]) then

                    local isCTRLKeyDown = IsControlKeyDown()
                    MethodDungeonTools:AddOrRemoveEnemyBlipToCurrentPull(i,not dungeonEnemyBlips[i].selected,isCTRLKeyDown)
                    MethodDungeonTools:UpdateEnemyBlipSelection(i,nil,isCTRLKeyDown)
                    MethodDungeonTools:UpdateEnemiesSelected()
                    break;
				end
			end
		end
	elseif (button=="RightButton") and MouseIsOver(MethodDungeonToolsScrollFrame) then
        if db.devMode then
            moverFrame:SetScript("OnUpdate",nil)
            moverFrame.isMoving = nil
            if currentBlip then
                if not currentBlip.devSelected then
                    currentBlip.devSelected = true
                else
                    currentBlip.devSelected = nil
                end
                for blipIdx,blip in pairs(dungeonEnemyBlips) do
                    if blip ~= currentBlip then
                        blip.devSelected = nil
                    end
                end
            end
            currentBlip = nil
            MethodDungeonTools:UpdateMap()
            return

        else
            cursorX, cursorY = GetCursorPosition()
            L_EasyMenu(MethodDungeonTools.contextMenuList, frame.contextDropdown, "cursor", 0 , -15, "MENU",5)
            frame.contextDropdown:Show()
        end
	end
end

---SetCurrentSubLevel
---Sets the sublevel of the currently active preset, need to UpdateMap to reflect the change in UI
function MethodDungeonTools:SetCurrentSubLevel(sublevel)
    db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel = sublevel
end


---GetCurrentSubLevel
---Returns the sublevel of the currently active preset
function MethodDungeonTools:GetCurrentSubLevel()
	return db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel
end

---GetCurrentPreset
---Returns the current preset
function MethodDungeonTools:GetCurrentPreset()
    return db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
end

---ShowBlipPatrol
---Displays patrol waypoints and lines
function MethodDungeonTools:ShowBlipPatrol(blip,show)
    if blip and blip.patrol then
        if show == true and blip.patrolActive then
            for patrolIdx,waypointBlip in ipairs(blip.patrol) do
                if waypointBlip.isActive then
                    waypointBlip:Show()
                    waypointBlip.line:Show()
                end
            end
        elseif show == false then
            for patrolIdx,waypointBlip in ipairs(blip.patrol) do
                waypointBlip:Hide()
                waypointBlip.line:Hide()
            end
        end
    end
end


function MethodDungeonTools:MakeMapTexture(frame)
    MethodDungeonTools.contextMenuList = {}

    tinsert(MethodDungeonTools.contextMenuList, {
        text = "Close",
        notCheckable = 1,
        func = frame.contextDropdown:Hide()
    })

	-- Scroll Frame
	if frame.scrollFrame == nil then
		frame.scrollFrame = CreateFrame("ScrollFrame", "MethodDungeonToolsScrollFrame",frame)
		frame.scrollFrame:ClearAllPoints();
		frame.scrollFrame:SetSize(840, 555);
		frame.scrollFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);

		-- Enable mousewheel scrolling
		frame.scrollFrame:EnableMouseWheel(true)
		frame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            MethodDungeonTools:ZoomMap(delta)
		end)

		--PAN
		frame.scrollFrame:EnableMouse(true)
		frame.scrollFrame:SetScript("OnMouseDown", MethodDungeonTools.OnMouseDown)
		frame.scrollFrame:SetScript("OnMouseUp", MethodDungeonTools.OnMouseUp)

		frame.scrollFrame:SetScript("OnHide", function()
			tooltipLastShown = nil
			tooltip.Model:Hide()
			tooltip:Hide()
		end)

        local lastMouseoverBlip
		frame.scrollFrame:SetScript("OnUpdate", function(self, button)
			local scrollFrame = MethodDungeonTools.main_frame.scrollFrame
            local frameX,frameY = MethodDungeonTools:GetCursorPosition()
			--MethodDungeonTools.main_frame.topPanelString:SetText(string.format("%.1f",frameX).."    "..string.format("%.1f",frameY));
			if ( scrollFrame.panning ) then
				local x, y = GetCursorPosition();
				MethodDungeonTools:OnPan(x, y);
			end
			--handle mouseover on enemy blips
			local mouseoverBlip
			if MouseIsOver(MethodDungeonToolsScrollFrame) then
				for i=1,numDungeonEnemyBlips do
					if MouseIsOver(dungeonEnemyBlips[i]) then
						mouseoverBlip = i
						break;
					end
				end
			end
			if mouseoverBlip then
				local data = dungeonEnemyBlips[mouseoverBlip]
				local fortified = false
				local boss = false
				if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix then
					if db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix == "fortified" then fortified = true end
				end
				local tyrannical = not fortified
				local health = MethodDungeonTools:CalculateEnemyHealth(boss,fortified,tyrannical,data.health,db.currentDifficulty)
				local group = data.g and " (G "..data.g..")" or ""
				local text = "\n\n"..data.name.." "..data.cloneIdx..group.."\nLevel "..data.level.." "..data.creatureType.."\n"..MethodDungeonTools:FormatEnemyHealth(health).." HP\n"
                text = text .."Enemy Forces: "..MethodDungeonTools:FormatEnemyForces(data.count)
                tooltip.String:SetText(text)
				tooltip.String:Show()
				tooltip:Show()
                if db.tooltipInCorner then
                    tooltip:SetPoint("BOTTOMRIGHT",MethodDungeonTools.main_frame,"BOTTOMRIGHT",0,0)
                    tooltip:SetPoint("TOPLEFT",MethodDungeonTools.main_frame,"BOTTOMRIGHT",-tooltip.mySizes.x,tooltip.mySizes.y)
                else
                    --check for bottom clipping
                    tooltip:SetPoint("TOPLEFT",dungeonEnemyBlips[mouseoverBlip],"BOTTOMRIGHT",30,0)
                    tooltip:SetPoint("BOTTOMRIGHT",dungeonEnemyBlips[mouseoverBlip],"BOTTOMRIGHT",30+tooltip.mySizes.x,-tooltip.mySizes.y)
                    local bottomOffset = 0
                    local rightOffset = 0
                    local tooltipBottom = tooltip:GetBottom()
                    local mainFrameBottom = MethodDungeonTools.main_frame:GetBottom()
                    if tooltipBottom<mainFrameBottom then
                        bottomOffset = tooltip.mySizes.y
                    end
                    --right side clipping
                    local tooltipRight = tooltip:GetRight()
                    local mainFrameRight = MethodDungeonTools.main_frame:GetRight()
                    if tooltipRight>mainFrameRight then
                        rightOffset = -(tooltip.mySizes.x+60)
                    end

                    tooltip:SetPoint("TOPLEFT",dungeonEnemyBlips[mouseoverBlip],"BOTTOMRIGHT",30+rightOffset,bottomOffset)
                    tooltip:SetPoint("BOTTOMRIGHT",dungeonEnemyBlips[mouseoverBlip],"BOTTOMRIGHT",30+tooltip.mySizes.x+rightOffset,-tooltip.mySizes.y+bottomOffset)
                end
				local id = dungeonEnemyBlips[mouseoverBlip].id
				if id then
					if lastModelId then
						if lastModelId ~= id then
							tooltip.Model:SetCreature(id)
							lastModelId = id
						end
					else
						tooltip.Model:SetCreature(id)
						lastModelId = id
					end
					tooltip.Model:Show()
				else
					tooltip.Model:ClearModel()
					tooltip.Model:Hide()
				end

				lastMouseoverBlip = mouseoverBlip
				tooltipLastShown = GetTime()
                for k,blip in pairs(dungeonEnemyBlips) do
                    if k == mouseoverBlip then
                        blip:SetSize(blip.storedSize*1.2,blip.storedSize*1.2)
                        blip:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.mouseover.blip)
                        blip.border:SetSize(blip.border.storedSize*1.2,blip.border.storedSize*1.2)
                        blip.border:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.mouseover.border)
                        blip.highlight:Show()
                        blip.highlight2:SetSize(blip.highlight2.storedSize*1.2,blip.highlight2.storedSize*1.2)
                        blip.highlight3:SetSize(blip.highlight3.storedSize*1.2,blip.highlight3.storedSize*1.2)
                        blip.dragon:SetSize(blip.dragon.storedSize*1.2,blip.dragon.storedSize*1.2)
                    else
                        blip:SetSize(blip.storedSize,blip.storedSize)
                        blip:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.normal.blip)
                        blip.border:SetSize(blip.border.storedSize,blip.border.storedSize)
                        blip.border:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.normal.border)
                        blip.highlight:Hide()
                        blip.highlight2:SetSize(blip.highlight2.storedSize,blip.highlight2.storedSize)
                        blip.highlight3:SetSize(blip.highlight3.storedSize,blip.highlight3.storedSize)
                        blip.dragon:SetSize(blip.dragon.storedSize,blip.dragon.storedSize)
                    end
                end

				--check if blip is in a patrol but not the "leader"
				if data.patrolFollower then
					for blipIdx,blip in pairs(dungeonEnemyBlips) do
						if blip:IsShown() and blip.g and data.g then
							if blip.g == data.g and blip.patrol then
								mouseoverBlip = blipIdx
							end
						end
					end
				end

				--display patrol waypoints and lines
				for idx,blip in pairs(dungeonEnemyBlips) do
					if blip.patrol then
						if idx == mouseoverBlip and blip.patrolActive then
							for patrolIdx,waypointBlip in ipairs(blip.patrol) do
                                if waypointBlip.isActive then
                                    waypointBlip:Show()
                                    waypointBlip.line:Show()
                                end
							end
						else
                            if not db.devMode or not blip.devSelected then
                                for patrolIdx,waypointBlip in ipairs(blip.patrol) do
                                    waypointBlip:Hide()
                                    waypointBlip.line:Hide()
                                end
                            end
						end
					end
				end

			elseif tooltipLastShown and GetTime()-tooltipLastShown>0.2 then
				tooltipLastShown = nil
				--GameTooltip:Hide()
				tooltip.Model:Hide()
				tooltip:Hide()
				--hide all patrol waypoints and facing indicators
                for blipIdx,blip in pairs(dungeonEnemyBlips) do
                    if not db.devMode or not blip.devSelected then
                        if blip.patrol then
                            for patrolIdx,waypointBlip in ipairs(blip.patrol) do
                                waypointBlip:Hide()
                                waypointBlip.line:Hide()
                            end
                        end
                    end
                end
                --reset mySizes
                for k,blip in pairs(dungeonEnemyBlips) do
                    blip:SetSize(blip.storedSize*1,blip.storedSize*1)
                    blip:SetDrawLayer(blipDrawLayer, 5)
                    blip.border:SetSize(blip.border.storedSize*1,blip.border.storedSize*1)
                    blip.border:SetDrawLayer(blipDrawLayer, 4)
                    blip.dragon:SetSize(blip.dragon.storedSize,blip.dragon.storedSize)
                    blip.highlight:Hide()
                    blip.highlight2:SetSize(blip.highlight2.storedSize,blip.highlight2.storedSize)
                    blip.highlight3:SetSize(blip.highlight3.storedSize,blip.highlight3.storedSize)
                end
			end

            MethodDungeonTools:UpdatePullTooltip(MethodDungeonTools.pullTooltip)
        end)



		if frame.mapPanelFrame == nil then
			frame.mapPanelFrame = CreateFrame("frame","MethodDungeonToolsMapPanelFrame",nil)
			frame.mapPanelFrame:ClearAllPoints();
			frame.mapPanelFrame:SetSize(frame:GetWidth(), frame:GetHeight());
			frame.mapPanelFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);

		end

		--create the 12 tiles and set the scrollchild
		for i=1,12 do
			frame["mapPanelTile"..i] = frame.mapPanelFrame:CreateTexture("MethodDungeonToolsmapPanelTile"..i, "BACKGROUND");
			frame["mapPanelTile"..i]:SetDrawLayer(canvasDrawLayer, 0);
			--frame["mapPanelTile"..i]:SetAlpha(0.3)
			frame["mapPanelTile"..i]:SetSize(frame:GetWidth()/4+4,frame:GetWidth()/4+4)
		end
		frame.mapPanelTile1:SetPoint("TOPLEFT",frame.mapPanelFrame,"TOPLEFT",1,0)
		frame.mapPanelTile2:SetPoint("TOPLEFT",frame.mapPanelTile1,"TOPRIGHT")
		frame.mapPanelTile3:SetPoint("TOPLEFT",frame.mapPanelTile2,"TOPRIGHT")
		frame.mapPanelTile4:SetPoint("TOPLEFT",frame.mapPanelTile3,"TOPRIGHT")
		frame.mapPanelTile5:SetPoint("TOPLEFT",frame.mapPanelTile1,"BOTTOMLEFT")
		frame.mapPanelTile6:SetPoint("TOPLEFT",frame.mapPanelTile5,"TOPRIGHT")
		frame.mapPanelTile7:SetPoint("TOPLEFT",frame.mapPanelTile6,"TOPRIGHT")
		frame.mapPanelTile8:SetPoint("TOPLEFT",frame.mapPanelTile7,"TOPRIGHT")
		frame.mapPanelTile9:SetPoint("TOPLEFT",frame.mapPanelTile5,"BOTTOMLEFT")
		frame.mapPanelTile10:SetPoint("TOPLEFT",frame.mapPanelTile9,"TOPRIGHT")
		frame.mapPanelTile11:SetPoint("TOPLEFT",frame.mapPanelTile10,"TOPRIGHT")
		frame.mapPanelTile12:SetPoint("TOPLEFT",frame.mapPanelTile11,"TOPRIGHT")
		frame.scrollFrame:SetScrollChild(frame.mapPanelFrame)
	end

end

local function round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end
function MethodDungeonTools:CalculateEnemyHealth(boss,fortified,tyrannical,baseHealth,level)
	local mult = 1
	if boss == false and fortified == true then mult = 1.2 end
	if boss == true and tyrannical == true then mult = 1.4 end
	mult = round((1.1^(level-1))*mult,2)
	return round(mult*baseHealth,0)
end

function MethodDungeonTools:FormatEnemyHealth(amount)
	amount = tonumber(amount)
    if amount < 1e3 then
        return string.sub(amount)
    elseif amount >= 1e12 then
        return string.format("%.3ft", amount/1e12)
    elseif amount >= 1e9 then
        return string.format("%.3fb", amount/1e9)
    elseif amount >= 1e6 then
        return string.format("%.2fm", amount/1e6)
    elseif amount >= 1e3 then
        return string.format("%.1fk", amount/1e3)
    end
end

function MethodDungeonTools:DisplayEncounterInformation(encounterID)

	--print(db.currentDungeonIdx)


end



local defaultBlipColor = {r=1,g=1,b=1,a=0.8}
local patrolColor = {r=0,g=.5,b=1,a=0.8}
MethodDungeonTools.BlipDrawlayers = {
    normal = {
        blip = 4,
        border = 3,
        highlight = 7,
        highlight2 = 7,
        highlight3 = 2,
        dragon = 1,
    },
    mouseover = {
        blip = 6,
        border = 5,
        highlight2 = 7,
        highlight3 = 4,
    },
}
function MethodDungeonTools:UpdateDungeonEnemies()
	if not dungeonEnemyBlips then
		dungeonEnemyBlips = {}
	end
    for _,blip in pairs(dungeonEnemyBlips) do
        blip:Hide()
        blip.border:Hide()
        blip.highlight:Hide()
        blip.highlight2:Hide()
        blip.highlight3:Hide()
        blip.dragon:Hide()
    end
	local idx = 1
	if MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx] then
		local enemies = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx]
		for enemyIdx,data in pairs(enemies) do
			for cloneIdx,clone in pairs(data["clones"]) do
				--check sublevel
				if (clone.sublevel and clone.sublevel == db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel) or ((not clone.sublevel) and db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel == 1) then
					--check for teeming
					local teeming = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
					if (teeming==true) or (teeming==false and ((not clone.teeming) or clone.teeming==false))  then
						if not dungeonEnemyBlips[idx] then
							dungeonEnemyBlips[idx] = MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture("MethodDungeonToolsDungeonEnemyBlip"..idx,"BACKGROUND")
							dungeonEnemyBlips[idx].selected = false
						end
                        local blip = dungeonEnemyBlips[idx]

						blip.count = data["count"]
						blip.name = data["name"]
						blip.color = data["color"]
                        blip.isBoss = data["isBoss"]
                        if not blip.color then
                            blip.color = defaultBlipColor
                        end

						dungeonEnemyBlips[idx].cloneIdx = cloneIdx
						dungeonEnemyBlips[idx].enemyIdx = enemyIdx
						dungeonEnemyBlips[idx].id = data["id"]
						dungeonEnemyBlips[idx].g = clone.g
						dungeonEnemyBlips[idx].stealth = data.stealth
						dungeonEnemyBlips[idx].stealthDetect = data.stealthDetect
						dungeonEnemyBlips[idx].neutral = data.neutral
						dungeonEnemyBlips[idx].teeming = clone.teeming
						dungeonEnemyBlips[idx].sublevel = clone.sublevel or 1
						dungeonEnemyBlips[idx].creatureType = data["creatureType"]
						dungeonEnemyBlips[idx].health = data["health"]
                        dungeonEnemyBlips[idx].level = data["level"]
                        dungeonEnemyBlips[idx]:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.normal.blip)
                        --seagull 39490 as placeholder for when the python script has not ran yet
                        SetPortraitTextureFromCreatureDisplayID(dungeonEnemyBlips[idx],data.displayId or 39490)
						dungeonEnemyBlips[idx]:SetAlpha(1)
                        --scale up blip if this is a boss
                        dungeonEnemyBlips[idx].scale = data["scale"]*(dungeonEnemyBlips[idx].isBoss and 1.7 or 1)
                        dungeonEnemyBlips[idx].storedSize = 8*dungeonEnemyBlips[idx].scale
						dungeonEnemyBlips[idx]:SetSize(dungeonEnemyBlips[idx].storedSize,dungeonEnemyBlips[idx].storedSize)
						dungeonEnemyBlips[idx]:SetPoint("CENTER",MethodDungeonTools.main_frame.mapPanelTile1,"TOPLEFT",clone.x,clone.y)

                        dungeonEnemyBlips[idx].border = dungeonEnemyBlips[idx].border or MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture(nil, "BACKGROUND")
                        dungeonEnemyBlips[idx].border:SetTexture("Interface\\AddOns\\MethodDungeonTools\\Textures\\UI-EncounterJournalTextures")
                        dungeonEnemyBlips[idx].border:SetTexCoord(0.85,0.97,0.43,0.4865)

                        --if dungeonEnemyBlips[idx].isBoss then dungeonEnemyBlips[idx].border:SetAtlas("worldquest-questmarker-dragon") end
                        dungeonEnemyBlips[idx].border:SetPoint("CENTER",dungeonEnemyBlips[idx],"CENTER",0,-0)
                        dungeonEnemyBlips[idx].border.storedSize = 12*dungeonEnemyBlips[idx].scale
                        dungeonEnemyBlips[idx].border:SetSize(dungeonEnemyBlips[idx].border.storedSize,dungeonEnemyBlips[idx].border.storedSize)
                        dungeonEnemyBlips[idx].border:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.normal.border)
                        dungeonEnemyBlips[idx].border:Show()

                        dungeonEnemyBlips[idx].highlight = dungeonEnemyBlips[idx].highlight or MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture(nil, "BACKGROUND")
                        dungeonEnemyBlips[idx].highlight:SetTexture("Interface\\AddOns\\MethodDungeonTools\\Textures\\UI-EncounterJournalTextures")
                        dungeonEnemyBlips[idx].highlight:SetTexCoord(0.69,0.81,0.39,0.333)
                        dungeonEnemyBlips[idx].highlight:SetPoint("CENTER",dungeonEnemyBlips[idx],"CENTER")
                        dungeonEnemyBlips[idx].highlight:SetSize(14*dungeonEnemyBlips[idx].scale,14*dungeonEnemyBlips[idx].scale)
                        dungeonEnemyBlips[idx].highlight:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.normal.highlight)
                        dungeonEnemyBlips[idx].highlight:SetAlpha(0.4)
                        dungeonEnemyBlips[idx].highlight:Hide()

                        dungeonEnemyBlips[idx].highlight2 = dungeonEnemyBlips[idx].highlight2 or MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture(nil, "BACKGROUND")
                        dungeonEnemyBlips[idx].highlight2:SetTexture("Interface\\AddOns\\MethodDungeonTools\\Textures\\UI-EncounterJournalTextures")
                        dungeonEnemyBlips[idx].highlight2:SetTexCoord(0.69,0.81,0.39,0.333)
                        dungeonEnemyBlips[idx].highlight2:SetPoint("CENTER",dungeonEnemyBlips[idx],"CENTER")
                        dungeonEnemyBlips[idx].highlight2.storedSize = 12*dungeonEnemyBlips[idx].scale
                        dungeonEnemyBlips[idx].highlight2:SetSize(dungeonEnemyBlips[idx].highlight2.storedSize,dungeonEnemyBlips[idx].highlight2.storedSize)
                        dungeonEnemyBlips[idx].highlight2:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.normal.highlight2)
                        dungeonEnemyBlips[idx].highlight2:SetVertexColor(unpack(selectedGreen))
                        dungeonEnemyBlips[idx].highlight2:Hide()

                        dungeonEnemyBlips[idx].highlight3 = dungeonEnemyBlips[idx].highlight3 or MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture(nil, "BACKGROUND")
                        dungeonEnemyBlips[idx].highlight3:SetTexture("Interface\\AddOns\\MethodDungeonTools\\Textures\\UI-EncounterJournalTextures")
                        dungeonEnemyBlips[idx].highlight3:SetTexCoord(0.69,0.81,0.39,0.333)
                        dungeonEnemyBlips[idx].highlight3:SetPoint("CENTER",dungeonEnemyBlips[idx],"CENTER")
                        dungeonEnemyBlips[idx].highlight3.storedSize = 14*dungeonEnemyBlips[idx].scale
                        dungeonEnemyBlips[idx].highlight3:SetSize(dungeonEnemyBlips[idx].highlight3.storedSize,dungeonEnemyBlips[idx].highlight3.storedSize)
                        dungeonEnemyBlips[idx].highlight3:SetDrawLayer(blipDrawLayer, MethodDungeonTools.BlipDrawlayers.normal.highlight3)
                        dungeonEnemyBlips[idx].highlight3:SetVertexColor(1,1,1,0.75)
                        dungeonEnemyBlips[idx].highlight3:Hide()

                        blip.dragon = blip.dragon or MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture(nil, "BACKGROUND")
                        blip.dragon:SetAtlas("worldquest-questmarker-dragon")
                        blip.dragon:SetPoint("CENTER",blip,"CENTER")
                        blip.dragon.storedSize = 14*dungeonEnemyBlips[idx].scale
                        blip.dragon:SetSize(blip.dragon.storedSize,blip.dragon.storedSize)
                        blip.dragon:SetDrawLayer(blipDrawLayer,MethodDungeonTools.BlipDrawlayers.normal.dragon)
                        blip.dragon:Hide()
                        if blip.isBoss then blip.dragon:Show() end

                        --color patrol
                        dungeonEnemyBlips[idx].patrolFollower = nil
                        if clone.patrol then
                            --dungeonEnemyBlips[idx]:SetTexture("Interface\\Worldmap\\WorldMapPlayerIcon")
                            dungeonEnemyBlips[idx].color = patrolColor
                        else
                            --iterate over all enemies again to find if this npc is linked to a patrol
                            for _,patrolCheckData in pairs(enemies) do
                                for _,patrolCheckClone in pairs(patrolCheckData["clones"]) do
                                    --check sublevel
                                    if (patrolCheckClone.sublevel and patrolCheckClone.sublevel == db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel) or ((not patrolCheckClone.sublevel) and db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel == 1) then
                                        --check for teeming
                                        local patrolCheckDataTeeming = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
                                        if (patrolCheckDataTeeming==true) or (patrolCheckDataTeeming==false and ((not patrolCheckClone.teeming) or patrolCheckClone.teeming==false))  then
                                            if clone.g and patrolCheckClone.g then
                                                if clone.g == patrolCheckClone.g and patrolCheckClone.patrol then
                                                    --dungeonEnemyBlips[idx]:SetTexture("Interface\\Worldmap\\WorldMapPlayerIcon")
                                                    dungeonEnemyBlips[idx].color = patrolColor
                                                    dungeonEnemyBlips[idx].patrolFollower = true
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

						if dungeonEnemyBlips[idx].selected == true then dungeonEnemyBlips[idx].border:SetVertexColor(0,1,0,1) else

                            local r,g,b,a = dungeonEnemyBlips[idx].color.r,dungeonEnemyBlips[idx].color.g,dungeonEnemyBlips[idx].color.b,dungeonEnemyBlips[idx].color.a
                            dungeonEnemyBlips[idx].border:SetVertexColor(r,g,b,a)
						end

						dungeonEnemyBlips[idx]:Show()


						--clear patrol flag
						if dungeonEnemyBlips[idx].patrol then
							dungeonEnemyBlips[idx].patrolActive = nil
						end

						--patrol waypoints/lines
                        if clone.patrol then


							dungeonEnemyBlips[idx].patrol = dungeonEnemyBlips[idx].patrol or {}
							local firstWaypointBlip
							local oldWaypointBlip

                            for k,v in pairs(dungeonEnemyBlips[idx].patrol) do
                                v.isActive = false
                            end

							for patrolIdx,waypoint in ipairs(clone.patrol) do
								if not dungeonEnemyBlips[idx].patrol[patrolIdx] then
								dungeonEnemyBlips[idx].patrol[patrolIdx] = MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture("MethodDungeonToolsDungeonEnemyBlip"..idx.."Patrol"..patrolIdx,"BACKGROUND")
								end
								dungeonEnemyBlips[idx].patrol[patrolIdx]:SetDrawLayer(blipDrawLayer, 2)
								dungeonEnemyBlips[idx].patrol[patrolIdx]:SetTexture("Interface\\Worldmap\\X_Mark_64Grey")
								dungeonEnemyBlips[idx].patrol[patrolIdx]:SetWidth(10*0.4)
								dungeonEnemyBlips[idx].patrol[patrolIdx]:SetHeight(10*0.4)
								dungeonEnemyBlips[idx].patrol[patrolIdx]:SetVertexColor(0,0.2,0.5,0.6)
								dungeonEnemyBlips[idx].patrol[patrolIdx]:SetPoint("CENTER",MethodDungeonTools.main_frame.mapPanelTile1,"TOPLEFT",waypoint.x,waypoint.y)
                                dungeonEnemyBlips[idx].patrol[patrolIdx].x = waypoint.x
                                dungeonEnemyBlips[idx].patrol[patrolIdx].y = waypoint.y
                                dungeonEnemyBlips[idx].patrol[patrolIdx]:Hide()
								dungeonEnemyBlips[idx].patrol[patrolIdx].isActive = true

								if not dungeonEnemyBlips[idx].patrol[patrolIdx].line then
									dungeonEnemyBlips[idx].patrol[patrolIdx].line = MethodDungeonTools.main_frame.mapPanelFrame:CreateTexture("MethodDungeonToolsDungeonEnemyBlip"..idx.."Patrol"..patrolIdx.."line","BACKGROUND")
								end
								dungeonEnemyBlips[idx].patrol[patrolIdx].line:SetDrawLayer(blipDrawLayer, 1)
								dungeonEnemyBlips[idx].patrol[patrolIdx].line:SetTexture("Interface\\AddOns\\MethodDungeonTools\\Textures\\Square_White")
								dungeonEnemyBlips[idx].patrol[patrolIdx].line:SetVertexColor(0,0.2,0.5,0.6)
								dungeonEnemyBlips[idx].patrol[patrolIdx].line:Hide()

								--connect 2 waypoints
								if oldWaypointBlip then
									local startPoint, startRelativeTo, startRelativePoint, startX, startY = dungeonEnemyBlips[idx].patrol[patrolIdx]:GetPoint()
									local endPoint, endRelativeTo, endRelativePoint, endX, endY = oldWaypointBlip:GetPoint()
									DrawLine(dungeonEnemyBlips[idx].patrol[patrolIdx].line, MethodDungeonTools.main_frame.mapPanelTile1, startX, startY, endX, endY, 1, 1,"TOPLEFT")
									dungeonEnemyBlips[idx].patrol[patrolIdx].line:Hide()
								else
									firstWaypointBlip = dungeonEnemyBlips[idx].patrol[patrolIdx]
								end
								oldWaypointBlip = dungeonEnemyBlips[idx].patrol[patrolIdx]
							end
							--connect last 2 waypoints
							if firstWaypointBlip and oldWaypointBlip then
								local startPoint, startRelativeTo, startRelativePoint, startX, startY = firstWaypointBlip:GetPoint()
								local endPoint, endRelativeTo, endRelativePoint, endX, endY = oldWaypointBlip:GetPoint()
								DrawLine(firstWaypointBlip.line, MethodDungeonTools.main_frame.mapPanelTile1, startX, startY, endX, endY, 1, 1,"TOPLEFT")
								firstWaypointBlip.line:Hide()
							end
							dungeonEnemyBlips[idx].patrolActive = true
						end

						idx = idx + 1
					end
				end
			end
		end
	end
	numDungeonEnemyBlips = idx-1
end

function MethodDungeonTools:HideAllDialogs()
	MethodDungeonTools.main_frame.presetCreationFrame:Hide()
	MethodDungeonTools.main_frame.presetImportFrame:Hide()
	MethodDungeonTools.main_frame.ExportFrame:Hide()
	MethodDungeonTools.main_frame.RenameFrame:Hide()
	MethodDungeonTools.main_frame.ClearConfirmationFrame:Hide()
	MethodDungeonTools.main_frame.DeleteConfirmationFrame:Hide()
end

function MethodDungeonTools:OpenImportPresetDialog()
	MethodDungeonTools:HideAllDialogs()
	MethodDungeonTools.main_frame.presetImportFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
	MethodDungeonTools.main_frame.presetImportFrame:Show()
	MethodDungeonTools.main_frame.presetImportBox:SetFocus()
end

function MethodDungeonTools:OpenNewPresetDialog()
	MethodDungeonTools:HideAllDialogs()
	local presetList = {}
	local countPresets = 0
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		if v.text ~= "<New Preset>" then
			table.insert(presetList,k,v.text)
			countPresets=countPresets+1
		end
	end
	table.insert(presetList,1,"Empty")
	MethodDungeonTools.main_frame.PresetCreationDropDown:SetList(presetList)
	MethodDungeonTools.main_frame.PresetCreationDropDown:SetValue(1)
	MethodDungeonTools.main_frame.PresetCreationEditbox:SetText("Preset "..countPresets+1)
	MethodDungeonTools.main_frame.presetCreationFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
	MethodDungeonTools.main_frame.presetCreationFrame:SetStatusText("")
	MethodDungeonTools.main_frame.presetCreationFrame:Show()
	MethodDungeonTools.main_frame.presetCreationCreateButton:SetDisabled(false)
	MethodDungeonTools.main_frame.PresetCreationEditbox:SetFocus()
	MethodDungeonTools.main_frame.PresetCreationEditbox:HighlightText(0,50)
	MethodDungeonTools.main_frame.presetImportBox:SetText("")
end

function MethodDungeonTools:UpdateSidePanelCheckBoxes()
	local frame = MethodDungeonTools.main_frame
	local affix = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix
	frame.sidePanelTyrannicalCheckBox:SetValue(affix~="fortified")
	frame.sidePanelFortifiedCheckBox:SetValue(affix=="fortified")


	local teeming = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
	frame.sidePanelTeemingCheckBox:SetValue(teeming)
	local teemingEnabled = MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teemingEnabled
	frame.sidePanelTeemingCheckBox:SetDisabled(not teemingEnabled)

end

function MethodDungeonTools:UpdateDungeonDropDown()
	local group = MethodDungeonTools.main_frame.DungeonSelectionGroup
    group.DungeonDropdown:SetList({})
    if db.currentExpansion == 1 then
        for i=1,14 do
            group.DungeonDropdown:AddItem(i,dungeonList[i])
        end
    elseif db.currentExpansion == 2 then
        for i=15,25 do
            group.DungeonDropdown:AddItem(i,dungeonList[i])
        end
    end
	group.DungeonDropdown:SetValue(db.currentDungeonIdx)
	group.SublevelDropdown:SetList(dungeonSubLevels[db.currentDungeonIdx])
	group.SublevelDropdown:SetValue(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel)
end

---CreateDungeonSelectDropdown
---Creates both dungeon and sublevel dropdowns
function MethodDungeonTools:CreateDungeonSelectDropdown(frame)
	--Simple Group to hold both dropdowns
	frame.DungeonSelectionGroup = AceGUI:Create("SimpleGroup")
	local group = frame.DungeonSelectionGroup
	group:SetWidth(200);
	group:SetHeight(50);
	group:SetPoint("TOPLEFT",frame.topPanel,"BOTTOMLEFT",0,2)
	group:SetLayout("List")

    MethodDungeonTools:FixAceGUIShowHide(group)

    --dungeon select
	group.DungeonDropdown = AceGUI:Create("Dropdown")
	group.DungeonDropdown.text:SetJustifyH("LEFT")
	group.DungeonDropdown:SetCallback("OnValueChanged",function(widget,callbackName,key)
		if key==14 or key == 25 then
            db.currentExpansion = (db.currentExpansion%2)+1
            db.currentDungeonIdx = key==14 and 15 or 1
            MethodDungeonTools:UpdateDungeonDropDown()
            MethodDungeonTools:UpdateToDungeon(db.currentDungeonIdx)
		else
            MethodDungeonTools:UpdateToDungeon(key)
		end
	end)
	group:AddChild(group.DungeonDropdown)

	--sublevel select
	group.SublevelDropdown = AceGUI:Create("Dropdown")
	group.SublevelDropdown.text:SetJustifyH("LEFT")
	group.SublevelDropdown:SetCallback("OnValueChanged",function(widget,callbackName,key)
		db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel = key
		MethodDungeonTools:UpdateMap()
        MethodDungeonTools:ZoomMap(1,true)
	end)
	group:AddChild(group.SublevelDropdown)

	MethodDungeonTools:UpdateDungeonDropDown()
end

---EnsureDBTables
---Makes sure profiles are valid and have their fields set
function MethodDungeonTools:EnsureDBTables()
	db.currentPreset[db.currentDungeonIdx] = db.currentPreset[db.currentDungeonIdx] or 1
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentAffix or "fortified"

    db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentDungeonIdx = db.currentDungeonIdx

	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming or false
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel or 1

	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull or 1
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls or {}
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull] = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull] or {}

	for k,v in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls) do
		if k ==0  then
			db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[0] = nil
			break;
		end
	end

end



function MethodDungeonTools:UpdateMap(ignoreSetSelection,ignoreReloadPullButtons)
	local mapName
	local frame = MethodDungeonTools.main_frame
	mapName = MethodDungeonTools.dungeonMaps[db.currentDungeonIdx][0]
	MethodDungeonTools:EnsureDBTables()
	local fileName = MethodDungeonTools.dungeonMaps[db.currentDungeonIdx][db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel]
	local path = "Interface\\WorldMap\\"..mapName.."\\";
	for i=1,12 do
		local texName = path..fileName..i;
		if frame["mapPanelTile"..i] then
			frame["mapPanelTile"..i]:SetTexture(texName)
		end
	end
	MethodDungeonTools:UpdateDungeonEnemies()
	if not ignoreReloadPullButtons then
		MethodDungeonTools:ReloadPullButtons()
	end
	MethodDungeonTools:UpdateSidePanelCheckBoxes()

	--handle delete button disable/enable
	local presetCount = 0
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		presetCount = presetCount + 1
	end
	if db.currentPreset[db.currentDungeonIdx] == 1 or db.currentPreset[db.currentDungeonIdx] == presetCount then
		MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(true)
	else
		MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
	end

	if not ignoreSetSelection then MethodDungeonTools:SetSelectionToPull(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull) end
	MethodDungeonTools:UpdateDungeonDropDown()
    MethodDungeonTools:POI_UpdateAll()
    MethodDungeonTools:DrawAllPresetObjects()
end

---UpdateToDungeon
---Updates the map to the specified dungeon
function MethodDungeonTools:UpdateToDungeon(dungeonIdx)
    db.currentDungeonIdx = dungeonIdx
	if not db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel then db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel=1 end
	MethodDungeonTools:UpdatePresetDropDown()
	MethodDungeonTools:UpdateMap()
    MethodDungeonTools:ZoomMap(1,true)
end

function MethodDungeonTools:DeletePreset(index)
	tremove(db.presets[db.currentDungeonIdx],index)
	db.currentPreset[db.currentDungeonIdx] = index-1
	MethodDungeonTools:UpdatePresetDropDown()
	MethodDungeonTools:UpdateMap()
end

function MethodDungeonTools:ClearPreset(index)
	table.wipe(db.presets[db.currentDungeonIdx][index].value.pulls)
	db.presets[db.currentDungeonIdx][index].value.currentPull = 1
	--MethodDungeonTools:DeleteAllPresetObjects()
	MethodDungeonTools:EnsureDBTables()
	MethodDungeonTools:UpdateMap()
	MethodDungeonTools:ReloadPullButtons()
end

function MethodDungeonTools:CreateNewPreset(name)
	if name == "<New Preset>" then
		MethodDungeonTools.main_frame.presetCreationLabel:SetText("Cannot create preset '"..name.."'")
		MethodDungeonTools.main_frame.presetCreationCreateButton:SetDisabled(true)
		MethodDungeonTools.main_frame.presetCreationFrame:DoLayout()
		return
	end
	local duplicate = false
	local countPresets = 0
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		countPresets = countPresets + 1
		if v.text == name then duplicate = true end
	end
	if duplicate == false then
		db.presets[db.currentDungeonIdx][countPresets+1] = db.presets[db.currentDungeonIdx][countPresets] --put <New Preset> at the end of the list

		local startingPointPresetIdx = MethodDungeonTools.main_frame.PresetCreationDropDown:GetValue()-1
		if startingPointPresetIdx>0 then
			db.presets[db.currentDungeonIdx][countPresets] = MethodDungeonTools:CopyObject(db.presets[db.currentDungeonIdx][startingPointPresetIdx])
			db.presets[db.currentDungeonIdx][countPresets].text = name
		else
			db.presets[db.currentDungeonIdx][countPresets] = {text=name,value={}}
		end

		db.currentPreset[db.currentDungeonIdx] = countPresets
		MethodDungeonTools.main_frame.presetCreationFrame:Hide()
		MethodDungeonTools:UpdatePresetDropDown()
		MethodDungeonTools:UpdateMap()
	else
		MethodDungeonTools.main_frame.presetCreationLabel:SetText("'"..name.."' already exists.")
		MethodDungeonTools.main_frame.presetCreationCreateButton:SetDisabled(true)
		MethodDungeonTools.main_frame.presetCreationFrame:DoLayout()
	end
end



function MethodDungeonTools:SanitizePresetName(text)
	--check if name is valid, block button if so, unblock if valid
	if text == "<New Preset>" then
		return false
	else
		local duplicate = false
		local countPresets = 0
		for k,v in pairs(db.presets[db.currentDungeonIdx]) do
			countPresets = countPresets + 1
			if v.text == text then duplicate = true end
		end
		return not duplicate and text or false
	end
end


function MethodDungeonTools:MakePresetImportFrame(frame)
	frame.presetImportFrame = AceGUI:Create("Frame")
	frame.presetImportFrame:SetTitle("Import Preset")
	frame.presetImportFrame:SetWidth(400)
	frame.presetImportFrame:SetHeight(200)
	frame.presetImportFrame:EnableResize(false)
	--frame.presetCreationFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame.presetImportFrame:SetLayout("Flow")
	frame.presetImportFrame:SetCallback("OnClose", function(widget)
		MethodDungeonTools:UpdatePresetDropDown()
		if db.currentPreset[db.currentDungeonIdx] ~= 1 then
			MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
		end
	end)

	frame.presetImportLabel = AceGUI:Create("Label")
	frame.presetImportLabel:SetText(nil)
	frame.presetImportLabel:SetWidth(390)
	frame.presetImportLabel:SetColor(1,0,0)

	local importString	= ""
	frame.presetImportBox = AceGUI:Create("EditBox")
	frame.presetImportBox:SetLabel("Import Preset:")
	frame.presetImportBox:SetWidth(255)
	frame.presetImportBox:SetCallback("OnEnterPressed", function(widget, event, text) importString = text end)
	frame.presetImportFrame:AddChild(frame.presetImportBox)

	local importButton = AceGUI:Create("Button")
	importButton:SetText("Import")
	importButton:SetWidth(100)
	importButton:SetCallback("OnClick", function()
		local newPreset = MethodDungeonTools:StringToTable(importString, true)
		if MethodDungeonTools:ValidateImportPreset(newPreset) then
			MethodDungeonTools.main_frame.presetImportFrame:Hide()
			MethodDungeonTools:ImportPreset(newPreset)
		else
			frame.presetImportLabel:SetText("Invalid import string")
		end
	end)
	frame.presetImportFrame:AddChild(importButton)
	frame.presetImportFrame:AddChild(frame.presetImportLabel)
	frame.presetImportFrame:Hide()

end

function MethodDungeonTools:MakePresetCreationFrame(frame)
	frame.presetCreationFrame = AceGUI:Create("Frame")
	frame.presetCreationFrame:SetTitle("New Preset")
	frame.presetCreationFrame:SetWidth(400)
	frame.presetCreationFrame:SetHeight(200)
	frame.presetCreationFrame:EnableResize(false)
	--frame.presetCreationFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame.presetCreationFrame:SetLayout("Flow")
	frame.presetCreationFrame:SetCallback("OnClose", function(widget)
		MethodDungeonTools:UpdatePresetDropDown()
		if db.currentPreset[db.currentDungeonIdx] ~= 1 then
			MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
		end
	end)


	frame.PresetCreationEditbox = AceGUI:Create("EditBox")
	frame.PresetCreationEditbox:SetLabel("Preset name:")
	frame.PresetCreationEditbox:SetWidth(255)
	frame.PresetCreationEditbox:SetCallback("OnEnterPressed", function(widget, event, text)
		--check if name is valid, block button if so, unblock if valid
		if MethodDungeonTools:SanitizePresetName(text) then
			frame.presetCreationLabel:SetText(nil)
			frame.presetCreationCreateButton:SetDisabled(false)
		else
			frame.presetCreationLabel:SetText("Cannot create preset '"..text.."'")
			frame.presetCreationCreateButton:SetDisabled(true)
		end
		frame.presetCreationFrame:DoLayout()
	end)
	frame.presetCreationFrame:AddChild(frame.PresetCreationEditbox)

	frame.presetCreationCreateButton = AceGUI:Create("Button")
	frame.presetCreationCreateButton:SetText("Create")
	frame.presetCreationCreateButton:SetWidth(100)
	frame.presetCreationCreateButton:SetCallback("OnClick", function()
		local name = frame.PresetCreationEditbox:GetText()
		MethodDungeonTools:CreateNewPreset(name)
	end)
	frame.presetCreationFrame:AddChild(frame.presetCreationCreateButton)

	frame.presetCreationLabel = AceGUI:Create("Label")
	frame.presetCreationLabel:SetText(nil)
	frame.presetCreationLabel:SetWidth(390)
	frame.presetCreationLabel:SetColor(1,0,0)
	frame.presetCreationFrame:AddChild(frame.presetCreationLabel)


	frame.PresetCreationDropDown = AceGUI:Create("Dropdown")
	frame.PresetCreationDropDown:SetLabel("Use as a starting point:")
	frame.PresetCreationDropDown.text:SetJustifyH("LEFT")
	frame.presetCreationFrame:AddChild(frame.PresetCreationDropDown)

	frame.presetCreationFrame:Hide()
end

function MethodDungeonTools:ValidateImportPreset(preset)
    if type(preset) ~= "table" then return false end
    if not preset.text then return false end
    if not preset.value then return false end
    if type(preset.text) ~= "string" then return false end
    if type(preset.value) ~= "table" then return false end
    if not preset.value.currentAffix then return false end
    if not preset.value.currentDungeonIdx then return false end
    if not preset.value.currentPull then return false end
    if not preset.value.currentSublevel then return false end
    if not preset.value.pulls then return false end
    if type(preset.value.pulls) ~= "table" then return false end
    return true
end

function MethodDungeonTools:ImportPreset(preset)
    --change dungeon to dungeon of the new preset
    MethodDungeonTools:UpdateToDungeon(preset.value.currentDungeonIdx)
	local name = preset.text
	local num = 2;
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		if name == v.text then
			name = preset.text.." "..num
			num = num + 1
		end
	end

	preset.text = name
	local countPresets = 0

	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		countPresets = countPresets + 1
	end
	db.presets[db.currentDungeonIdx][countPresets+1] = db.presets[db.currentDungeonIdx][countPresets] --put <New Preset> at the end of the list
	db.presets[db.currentDungeonIdx][countPresets] = preset
	db.currentPreset[db.currentDungeonIdx] = countPresets
	MethodDungeonTools:UpdatePresetDropDown()
	MethodDungeonTools:UpdateMap()
end

function MethodDungeonTools:MakePullSelectionButtons(frame)
    frame.PullButtonScrollGroup = AceGUI:Create("SimpleGroup")
    frame.PullButtonScrollGroup:SetWidth(249);
    frame.PullButtonScrollGroup:SetHeight(410)
    frame.PullButtonScrollGroup:SetPoint("TOPLEFT",frame.WidgetGroup.frame,"BOTTOMLEFT",-4,-32)
    frame.PullButtonScrollGroup:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,30)
    frame.PullButtonScrollGroup:SetLayout("Fill")
    frame.PullButtonScrollGroup.frame:SetFrameStrata(mainFrameStrata)
    frame.PullButtonScrollGroup.frame:SetBackdropColor(1,1,1,0)
    frame.PullButtonScrollGroup.frame:Show()

    MethodDungeonTools:FixAceGUIShowHide(frame.PullButtonScrollGroup)

    frame.pullButtonsScrollFrame = AceGUI:Create("ScrollFrame")
    frame.pullButtonsScrollFrame:SetLayout("Flow")

    frame.PullButtonScrollGroup:AddChild(frame.pullButtonsScrollFrame)

    frame.newPullButtons = {}
	--rightclick context menu
	frame.optionsDropDown = CreateFrame("Frame", "PullButtonsOptionsDropDown", nil, "L_UIDropDownMenuTemplate")
end


function MethodDungeonTools:PresetsAddPull(index)
	if index then
		tinsert(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls,index,{})
	else
		tinsert(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls,{})
	end
end

function MethodDungeonTools:PresetsDeletePull(p,j)
	tremove(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls,p)
end

function MethodDungeonTools:CopyObject(obj,seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[MethodDungeonTools:CopyObject(k, s)] = MethodDungeonTools:CopyObject(v, s) end
    return res
end

function MethodDungeonTools:PresetsSwapPulls(p1,p2)

	local p1copy = MethodDungeonTools:CopyObject(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[p1])
	local p2copy = MethodDungeonTools:CopyObject(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[p2])
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[p1] = p2copy
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[p2] = p1copy
end

function MethodDungeonTools:SetMapSublevel(pull)
	--set map sublevel
	local shouldResetZoom = false
	local lastSubLevel
	for enemyIdx,clones in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[pull]) do
		for idx,cloneIdx in pairs(clones) do
			if MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx] then
				lastSubLevel = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].sublevel
			end
		end
	end
	if lastSubLevel then
		shouldResetZoom = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel ~= lastSubLevel
		db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel = lastSubLevel
		MethodDungeonTools:UpdateMap(true,true)
	end

	MethodDungeonTools:UpdateDungeonDropDown()
    if shouldResetZoom then MethodDungeonTools:ZoomMap(1,true) end
end


function MethodDungeonTools:SetSelectionToPull(pull)
	--if pull is not specified set pull to last pull in preset (for adding new pulls)
	if not pull then
		local count = 0
		for k,v in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls) do
			count = count + 1
		end
		pull = count
	end
	--SaveCurrentPresetPull
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull = pull
	MethodDungeonTools:PickPullButton(pull)


	--deselect all
	for k,v in pairs(dungeonEnemyBlips) do
		MethodDungeonTools:UpdateEnemyBlipSelection(k,true)
	end

	--highlight current pull enemies
	for enemyIdx,clones in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[pull]) do
		for j,cloneIdx in pairs(clones) do
			for k,v in ipairs(dungeonEnemyBlips) do
				if (v.enemyIdx == enemyIdx) and (v.cloneIdx == cloneIdx) then
					MethodDungeonTools:UpdateEnemyBlipSelection(k,nil,true)
				end
			end
		end
	end

	--highlight other pull enemies
	for pullIdx,p in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls) do
        if pullIdx~=pull then
            for enemyIdx,clones in pairs(p) do
                for j,cloneIdx in pairs(clones) do
                    for k,v in ipairs(dungeonEnemyBlips) do
                        if (v.enemyIdx == enemyIdx) and (v.cloneIdx == cloneIdx) then
                            MethodDungeonTools:UpdateEnemyBlipSelection(k,nil,true,true)
                        end
                    end
                end
            end
        end
	end
    for k,v in ipairs(dungeonEnemyBlips) do
        if db.devMode and v.devSelected then
            v.border:SetVertexColor(1,0,0,1)
        end
    end


	MethodDungeonTools:UpdateEnemiesSelected()
end

function MethodDungeonTools:GetDungeonEnemyBlips()
    return dungeonEnemyBlips
end

---UpdatePullButtonNPCData
---Updates the portraits display of a button to show which and how many npcs are selected
function MethodDungeonTools:UpdatePullButtonNPCData(idx)
    if db.devMode then return end
	local preset = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
	local frame = MethodDungeonTools.main_frame.sidePanel
    local teeming = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
	local enemyTable = {}
	if preset.value.pulls[idx] then
		local enemyTableIdx = 0
		for enemyIdx,clones in pairs(preset.value.pulls[idx]) do
            --check if enemy exists, remove if not
            if not MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx] then

            else
                local incremented = false
                local npcId = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["id"]
                local name = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["name"]
                local creatureType = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["creatureType"]
                local level = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["level"]
                local baseHealth = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["health"]
                for k,cloneIdx in pairs(clones) do
                    --check if clone exists, remove if not
                    if not MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx] then

                    else
                        --check for teeming
                        local cloneIsTeeming = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].teeming
                        if (cloneIsTeeming and teeming) or (not cloneIsTeeming and not teeming) or (not cloneIsTeeming and teeming) then
                            if not incremented then enemyTableIdx = enemyTableIdx + 1; incremented = true end
                            if not enemyTable[enemyTableIdx] then enemyTable[enemyTableIdx] = {} end
                            enemyTable[enemyTableIdx].quantity = enemyTable[enemyTableIdx].quantity or 0
                            enemyTable[enemyTableIdx].npcId = npcId
                            enemyTable[enemyTableIdx].count = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["count"]
                            enemyTable[enemyTableIdx].displayId = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["displayId"]
                            enemyTable[enemyTableIdx].quantity = enemyTable[enemyTableIdx].quantity + 1
                            enemyTable[enemyTableIdx].name = name
                            enemyTable[enemyTableIdx].level = level
                            enemyTable[enemyTableIdx].creatureType = creatureType
                            enemyTable[enemyTableIdx].baseHealth = baseHealth
                        end
                    end
                end
            end
		end
	end
	frame.newPullButtons[idx]:SetNPCData(enemyTable)
end


---ReloadPullButtons
---Reloads all pull buttons in the scroll frame
function MethodDungeonTools:ReloadPullButtons()
	local frame = MethodDungeonTools.main_frame.sidePanel
	local preset = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
	--first release all children of the scroll frame
	frame.pullButtonsScrollFrame:ReleaseChildren()
	local maxPulls =  0
	for k,v in pairs(preset.value.pulls) do
		maxPulls = maxPulls + 1
	end
	--add new children to the scrollFrame, the frames are from the widget pool so no memory is wasted
    if not db.devMode then
        local idx = 0
        for k,pull in pairs(preset.value.pulls) do
            idx = idx+1
            frame.newPullButtons[idx] = AceGUI:Create("MethodDungeonToolsPullButton")
            frame.newPullButtons[idx]:SetMaxPulls(maxPulls)
            frame.newPullButtons[idx]:SetIndex(idx)
            MethodDungeonTools:UpdatePullButtonNPCData(idx)
            frame.newPullButtons[idx]:Initialize()
            frame.newPullButtons[idx]:Enable()
            frame.pullButtonsScrollFrame:AddChild(frame.newPullButtons[idx])
        end
    end
	--add the "new pull" button
	frame.newPullButton = AceGUI:Create("MethodDungeonToolsNewPullButton")
	frame.newPullButton:Initialize()
	frame.newPullButton:Enable()
	frame.pullButtonsScrollFrame:AddChild(frame.newPullButton)
end

---ClearPullButtonPicks
---Deselects all pull buttons
function MethodDungeonTools:ClearPullButtonPicks()
	local frame = MethodDungeonTools.main_frame.sidePanel
	for k,v in pairs(frame.newPullButtons) do
		v:ClearPick()
	end
end

---PickPullButton
---Selects the current pull button and deselects all other buttons
function MethodDungeonTools:PickPullButton(idx)
    if db.devMode then return end
	MethodDungeonTools:ClearPullButtonPicks()
	local frame = MethodDungeonTools.main_frame.sidePanel
	frame.newPullButtons[idx]:Pick()
end

---AddPull
---Creates a new pull in the current preset and calls ReloadPullButtons to reflect the change in the scrollframe
function MethodDungeonTools:AddPull(index)
	MethodDungeonTools:PresetsAddPull(index)
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index)
end

---ClearPull
---Clears all the npcs out of a pull
function MethodDungeonTools:ClearPull(index)
	table.wipe(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[index])
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index)
end

---MovePullUp
---Moves the selected pull up
function MethodDungeonTools:MovePullUp(index)
	MethodDungeonTools:PresetsSwapPulls(index,index-1)
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index-1)
end

---MovePullDown
---Moves the selected pull down
function MethodDungeonTools:MovePullDown(index)
	MethodDungeonTools:PresetsSwapPulls(index,index+1)
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index+1)
end

---DeletePull
---Deletes the selected pull and makes sure that a pull will be selected afterwards
function MethodDungeonTools:DeletePull(index)

	MethodDungeonTools:PresetsDeletePull(index)
	MethodDungeonTools:ReloadPullButtons()
	local pullCount = 0
	for k,v in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls) do
		pullCount = pullCount + 1
	end
	if index>pullCount then index = pullCount end
	MethodDungeonTools:SetSelectionToPull(index)

end

---RenamePreset
function MethodDungeonTools:RenamePreset(renameText)
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text = renameText
	MethodDungeonTools.main_frame.RenameFrame:Hide()
	MethodDungeonTools:UpdatePresetDropDown()
end


function MethodDungeonTools:MakeRenameFrame(frame)
	frame.RenameFrame = AceGUI:Create("Frame")
	frame.RenameFrame:SetTitle("Rename Preset")
	frame.RenameFrame:SetWidth(350)
	frame.RenameFrame:SetHeight(150)
	frame.RenameFrame:EnableResize(false)
	frame.RenameFrame:SetLayout("Flow")
	frame.RenameFrame:SetCallback("OnClose", function(widget)

	end)
	frame.RenameFrame:Hide()

	local renameText
	frame.RenameFrame.Editbox = AceGUI:Create("EditBox")
	frame.RenameFrame.Editbox:SetLabel("Insert new Preset Name:")
	frame.RenameFrame.Editbox:SetWidth(200)
	frame.RenameFrame.Editbox:SetCallback("OnEnterPressed", function(...)
        local widget, event, text = ...
		--check if name is valid, block button if so, unblock if valid
		if MethodDungeonTools:SanitizePresetName(text) then
			frame.RenameFrame.PresetRenameLabel:SetText(nil)
			frame.RenameFrame.RenameButton:SetDisabled(false)
			renameText = text
		else
			frame.RenameFrame.PresetRenameLabel:SetText("Cannot rename preset to '"..text.."'")
			frame.RenameFrame.RenameButton:SetDisabled(true)
			renameText = nil
		end
		frame.presetCreationFrame:DoLayout()
	end)

	frame.RenameFrame:AddChild(frame.RenameFrame.Editbox)

	frame.RenameFrame.RenameButton = AceGUI:Create("Button")
	frame.RenameFrame.RenameButton:SetText("Rename")
	frame.RenameFrame.RenameButton:SetWidth(100)
	frame.RenameFrame.RenameButton:SetCallback("OnClick",function() MethodDungeonTools:RenamePreset(renameText) end)
	frame.RenameFrame:AddChild(frame.RenameFrame.RenameButton)

	frame.RenameFrame.PresetRenameLabel = AceGUI:Create("Label")
	frame.RenameFrame.PresetRenameLabel:SetText(nil)
	frame.RenameFrame.PresetRenameLabel:SetWidth(390)
	frame.RenameFrame.PresetRenameLabel:SetColor(1,0,0)
	frame.RenameFrame:AddChild(frame.RenameFrame.PresetRenameLabel)

end


---MakeExportFrame
---Creates the frame used to export presets to a string which can be uploaded to text sharing websites like pastebin
---@param frame frame
function MethodDungeonTools:MakeExportFrame(frame)
	frame.ExportFrame = AceGUI:Create("Frame")
	frame.ExportFrame:SetTitle("Preset Export")
	frame.ExportFrame:SetWidth(600)
	frame.ExportFrame:SetHeight(400)
	frame.ExportFrame:EnableResize(false)
	frame.ExportFrame:SetLayout("Flow")
	frame.ExportFrame:SetCallback("OnClose", function(widget)

	end)

	frame.ExportFrameEditbox = AceGUI:Create("MultiLineEditBox")
	frame.ExportFrameEditbox:SetLabel("Preset Export:")
	frame.ExportFrameEditbox:SetWidth(600)
	frame.ExportFrameEditbox:DisableButton(true)
	frame.ExportFrameEditbox:SetNumLines(20)
	frame.ExportFrameEditbox:SetCallback("OnEnterPressed", function(widget, event, text)

	end)
	frame.ExportFrame:AddChild(frame.ExportFrameEditbox)
	--frame.presetCreationFrame:SetStatusText("AceGUI-3.0 Example Container Frame")
	frame.ExportFrame:Hide()
end


---MakeDeleteConfirmationFrame
---Creates the delete confirmation dialog that pops up when a user wants to delete a preset
function MethodDungeonTools:MakeDeleteConfirmationFrame(frame)
	frame.DeleteConfirmationFrame = AceGUI:Create("Frame")
	frame.DeleteConfirmationFrame:SetTitle("Delete Preset")
	frame.DeleteConfirmationFrame:SetWidth(250)
	frame.DeleteConfirmationFrame:SetHeight(120)
	frame.DeleteConfirmationFrame:EnableResize(false)
	frame.DeleteConfirmationFrame:SetLayout("Flow")
	frame.DeleteConfirmationFrame:SetCallback("OnClose", function(widget)

	end)

	frame.DeleteConfirmationFrame.label = AceGUI:Create("Label")
	frame.DeleteConfirmationFrame.label:SetWidth(390)
	frame.DeleteConfirmationFrame.label:SetHeight(10)
	--frame.DeleteConfirmationFrame.label:SetColor(1,0,0)
	frame.DeleteConfirmationFrame:AddChild(frame.DeleteConfirmationFrame.label)

	frame.DeleteConfirmationFrame.OkayButton = AceGUI:Create("Button")
	frame.DeleteConfirmationFrame.OkayButton:SetText("Delete")
	frame.DeleteConfirmationFrame.OkayButton:SetWidth(100)
	frame.DeleteConfirmationFrame.OkayButton:SetCallback("OnClick",function()
		MethodDungeonTools:DeletePreset(db.currentPreset[db.currentDungeonIdx])
		frame.DeleteConfirmationFrame:Hide()
	end)
	frame.DeleteConfirmationFrame.CancelButton = AceGUI:Create("Button")
	frame.DeleteConfirmationFrame.CancelButton:SetText("Cancel")
	frame.DeleteConfirmationFrame.CancelButton:SetWidth(100)
	frame.DeleteConfirmationFrame.CancelButton:SetCallback("OnClick",function()
		frame.DeleteConfirmationFrame:Hide()
	end)

	frame.DeleteConfirmationFrame:AddChild(frame.DeleteConfirmationFrame.OkayButton)
	frame.DeleteConfirmationFrame:AddChild(frame.DeleteConfirmationFrame.CancelButton)
	frame.DeleteConfirmationFrame:Hide()

end


---MakeClearConfirmationFrame
---Creates the clear confirmation dialog that pops up when a user wants to clear a preset
function MethodDungeonTools:MakeClearConfirmationFrame(frame)
	frame.ClearConfirmationFrame = AceGUI:Create("Frame")
	frame.ClearConfirmationFrame:SetTitle("Clear Preset")
	frame.ClearConfirmationFrame:SetWidth(250)
	frame.ClearConfirmationFrame:SetHeight(120)
	frame.ClearConfirmationFrame:EnableResize(false)
	frame.ClearConfirmationFrame:SetLayout("Flow")
	frame.ClearConfirmationFrame:SetCallback("OnClose", function(widget)

	end)

	frame.ClearConfirmationFrame.label = AceGUI:Create("Label")
	frame.ClearConfirmationFrame.label:SetWidth(390)
	frame.ClearConfirmationFrame.label:SetHeight(10)
	--frame.DeleteConfirmationFrame.label:SetColor(1,0,0)
	frame.ClearConfirmationFrame:AddChild(frame.ClearConfirmationFrame.label)

	frame.ClearConfirmationFrame.OkayButton = AceGUI:Create("Button")
	frame.ClearConfirmationFrame.OkayButton:SetText("Clear")
	frame.ClearConfirmationFrame.OkayButton:SetWidth(100)
	frame.ClearConfirmationFrame.OkayButton:SetCallback("OnClick",function()
		MethodDungeonTools:ClearPreset(db.currentPreset[db.currentDungeonIdx])
		frame.ClearConfirmationFrame:Hide()
	end)
	frame.ClearConfirmationFrame.CancelButton = AceGUI:Create("Button")
	frame.ClearConfirmationFrame.CancelButton:SetText("Cancel")
	frame.ClearConfirmationFrame.CancelButton:SetWidth(100)
	frame.ClearConfirmationFrame.CancelButton:SetCallback("OnClick",function()
		frame.ClearConfirmationFrame:Hide()
	end)

	frame.ClearConfirmationFrame:AddChild(frame.ClearConfirmationFrame.OkayButton)
	frame.ClearConfirmationFrame:AddChild(frame.ClearConfirmationFrame.CancelButton)
	frame.ClearConfirmationFrame:Hide()

end


---CreateTutorialButton
---Creates the tutorial button and sets up the help plate frames
function MethodDungeonTools:CreateTutorialButton(parent)
    local button = CreateFrame("Button",parent,parent,"MainHelpPlateButton")
    button:SetPoint("TOPLEFT",parent,"TOPLEFT",0,48)
	button:SetScale(0.8)
	button:SetFrameStrata(mainFrameStrata)
	button:SetFrameLevel(6)
	button:Hide()
	--hook to make button hide
	local originalHide = parent.Hide
	function parent:Hide(...)
		button:Hide()
		return originalHide(self, ...);
	end
	local helpPlate = {
		FramePos = { x = 0,	y = 0 },
		FrameSize = { width = sizex, height = sizey	},
		[1] = { ButtonPos = { x = 190,	y = 0 }, HighLightBox = { x = 0, y = 0, width = 197, height = 56 },		ToolTipDir = "RIGHT",		ToolTipText = "Select a dungeon" },
		[2] = { ButtonPos = { x = 190,	y = -210 }, HighLightBox = { x = 0, y = -58, width = sizex-6, height = sizey-58 },	ToolTipDir = "RIGHT",	ToolTipText = "Select enemies for your pulls\nCTRL+Click to single select enemies" },
		[3] = { ButtonPos = { x = 828,	y = 0 }, HighLightBox = { x = 838, y = 30, width = 251, height = 87 },	ToolTipDir = "LEFT",	ToolTipText = "Manage presets" },
		[4] = { ButtonPos = { x = 828,	y = -87 }, HighLightBox = { x = 838, y = 30-87, width = 251, height = 83 },	ToolTipDir = "LEFT",	ToolTipText = "Customize dungeon Options" },
		[5] = { ButtonPos = { x = 828,	y = -(87+83) }, HighLightBox = { x = 838, y = 30-(87+83), width = 251, height = 415 },	ToolTipDir = "LEFT",	ToolTipText = "Create and manage your pulls\nRight click for more options" },
	}
	local function TutorialButtonOnClick(self)
		if not HelpPlate_IsShowing(helpPlate) then
			HelpPlate_Show(helpPlate, MethodDungeonTools.main_frame, self)
		else
			HelpPlate_Hide(true)
		end
	end
	local function TutorialButtonOnHide(self)
		HelpPlate_Hide(true)
	end
	parent.HelpButton = button
    button:SetScript("OnClick",TutorialButtonOnClick)
    button:SetScript("OnHide",TutorialButtonOnHide)
end

---RegisterOptions
---Register the options of the addon to the blizzard options
function MethodDungeonTools:RegisterOptions()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("MethodDungeonTools", MethodDungeonTools.blizzardOptionsMenuTable);
	self.blizzardOptionsMenu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MethodDungeonTools", "MethodDungeonTools");
end

---Round
function MethodDungeonTools:Round(number, decimals)
	return (("%%.%df"):format(decimals)):format(number)
end

---RGBToHex
function MethodDungeonTools:RGBToHex(r,g,b)
	r = r*255
	g = g*255
	b = b*255
	return ("%.2x%.2x%.2x"):format(r, g, b)
end
---HexToRGB
function MethodDungeonTools:HexToRGB(rgb)
	if string.len(rgb) == 6 then
		local r, g, b
		r, g, b = tonumber('0x'..strsub(rgb, 0, 2)), tonumber('0x'..strsub(rgb, 3, 4)), tonumber('0x'..strsub(rgb, 5, 6))
		if not r then r = 0 else r = r/255 end
		if not g then g = 0 else g = g/255 end
		if not b then b = 0 else b = b/255 end
		return r,g,b
	else
		return
	end
end

---DeepCopy
function MethodDungeonTools:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[MethodDungeonTools:DeepCopy(orig_key)] = MethodDungeonTools:DeepCopy(orig_value)
        end
        setmetatable(copy, MethodDungeonTools:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---StorePresetObject
function MethodDungeonTools:StorePresetObject(obj)
	local currentPreset = MethodDungeonTools:GetCurrentPreset()
	currentPreset.objects = currentPreset.objects or {}
	--we insert the object infront of the first hidden oject
	local pos = 1
	for k,v in ipairs(currentPreset.objects) do
		pos = pos + 1
		if v.d[4]==false then
			pos = pos - 1
		end
	end
	if pos>1 then
		tinsert(currentPreset.objects,pos,MethodDungeonTools:DeepCopy(obj))
	else
		tinsert(currentPreset.objects,MethodDungeonTools:DeepCopy(obj))
	end
end

---UpdatePresetObjectOffsets
function MethodDungeonTools:UpdatePresetObjectOffsets(idx,x,y)
	local currentPreset = MethodDungeonTools:GetCurrentPreset()
	for objectIndex,obj in pairs(currentPreset.objects) do
		if objectIndex == idx then
			for coordIdx,coord in pairs(obj.l) do
				if coordIdx%2==1 then
					obj.l[coordIdx] = coord-x
				else
					obj.l[coordIdx] = coord-y
				end
			end
		end
	end
    --redraw everything
	MethodDungeonTools:DrawAllPresetObjects()
end


---DrawAllPresetObjects
---Draws all Preset objects on the map canvas/sublevel
function MethodDungeonTools:DrawAllPresetObjects()

    local currentPreset = MethodDungeonTools:GetCurrentPreset()
    local currentSublevel = MethodDungeonTools:GetCurrentSubLevel()

	--ViragDevTool_AddData(currentPreset.objects)
	--ViragDevTool_AddData(currentPreset)
	--ViragDevTool_AddData(string.len(MethodDungeonTools:TableToString(currentPreset, true)))

    MethodDungeonTools:ReleaseAllActiveTextures()
    currentPreset.objects = currentPreset.objects or {}
    --ViragDevTool_AddData(currentPreset.objects)
	--d: size,lineFactor,sublevel,shown,colorstring,drawLayer,[smooth]
	--l: x1,y1,x2,y2,...
	local color = {}
    for objectIndex,obj in pairs(currentPreset.objects) do
        if obj.d[3] == currentSublevel and obj.d[4] then
			color.r,color.g,color.b = MethodDungeonTools:HexToRGB(obj.d[5])
            --lines
            local x1,y1,x2,y2
			local lastx,lasty
            for _,coord in pairs(obj.l) do
				if not x1 then x1 = coord
				elseif not y1 then y1 = coord
				elseif not x2 then
					x2 = coord
					lastx = coord
				elseif not y2 then
					y2 = coord
					lasty = coord
				end
				if x1 and y1 and x2 and y2 then
					MethodDungeonTools:DrawLine(x1,y1,x2,y2,obj.d[1]*0.3,color,obj.d[7],nil,obj.d[6],obj.d[2],nil,objectIndex)
					--circles if smooth
					if obj.d[7] then
						MethodDungeonTools:DrawCircle(x1,y1,obj.d[1]*0.3,color,nil,obj.d[6],nil,objectIndex)
						MethodDungeonTools:DrawCircle(x2,y2,obj.d[1]*0.3,color,nil,obj.d[6],nil,objectIndex)
					end
					x1,y1,x2,y2 = nil,nil,nil,nil
				end
            end
            --triangle
            if obj.t and lastx and lasty then
                MethodDungeonTools:DrawTriangle(lastx,lasty,obj.t[1],obj.d[1],color,nil,obj.d[6],nil,objectIndex)
            end
			--remove empty objects leftover from erasing
			if obj.l then
				local lineCount = 0
				for _,_ in pairs(obj.l) do
					lineCount = lineCount +1
				end
				if lineCount == 0 then
					currentPreset.objects[objectIndex] = nil
				end
			end
        end
    end
end

---DeletePresetObjects
---Deletes objects from the current preset in the current sublevel
function MethodDungeonTools:DeletePresetObjects()
	local currentPreset = MethodDungeonTools:GetCurrentPreset()
    local currentSublevel = MethodDungeonTools:GetCurrentSubLevel()
    for objectIndex,obj in pairs(currentPreset.objects) do
        if obj.d[3] == currentSublevel then
            currentPreset.objects[objectIndex] = nil
        end
    end
    MethodDungeonTools:DrawAllPresetObjects()
end

---StepBack
---Undo the latest drawing
function MethodDungeonTools:PresetObjectStepBack()
    local currentPreset = MethodDungeonTools:GetCurrentPreset()
    currentPreset.objects = currentPreset.objects or {}
    local length = 0
    for k,v in pairs(currentPreset.objects) do
        length = length + 1
    end
    if length>0 then
        for i = length,1,-1 do
            if currentPreset.objects[i] and currentPreset.objects[i].d[4] then
                currentPreset.objects[i].d[4] = false
                MethodDungeonTools:DrawAllPresetObjects()
                break
            end
        end
    end
end

---StepForward
---Redo the latest drawing
function MethodDungeonTools:PresetObjectStepForward()
    local currentPreset = MethodDungeonTools:GetCurrentPreset()
    currentPreset.objects = currentPreset.objects or {}
    local length = 0
    for k,v in ipairs(currentPreset.objects) do
        length = length + 1
    end
    if length>0 then
        for i = 1,length do
            if currentPreset.objects[i] and not currentPreset.objects[i].d[4] then
                currentPreset.objects[i].d[4] = true
                MethodDungeonTools:DrawAllPresetObjects()
                break
            end
        end
    end
end

function MethodDungeonTools:FixAceGUIShowHide(widget,frame)
    frame = frame or MethodDungeonTools.main_frame
    local originalShow,originalHide = frame.Show,frame.Hide
    function frame:Show(...)
        widget.frame:Show()
        return originalShow(self, ...);
    end
    function frame:Hide(...)
        widget.frame:Hide()
        return originalHide(self, ...);
    end
end

function initFrames()
	local main_frame = CreateFrame("frame", "MethodDungeonToolsFrame", UIParent)

	main_frame:SetFrameStrata(mainFrameStrata)
	main_frame:SetFrameLevel(1)
	main_frame.background = main_frame:CreateTexture(nil, "BACKGROUND")
	main_frame.background:SetAllPoints()
	main_frame.background:SetDrawLayer(canvasDrawLayer, 1)
	main_frame.background:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))
	main_frame.background:SetAlpha(0.2)
	main_frame:SetSize(sizex, sizey)
	MethodDungeonTools.main_frame = main_frame

	tinsert(UISpecialFrames,"MethodDungeonToolsFrame")
	-- Set frame position
	main_frame:ClearAllPoints();
	main_frame:SetPoint(db.anchorTo, UIParent,db.anchorFrom, db.xoffset, db.yoffset)

    main_frame.contextDropdown = CreateFrame("Frame", "MethodDungeonToolsContextDropDown", nil, "L_UIDropDownMenuTemplate")

	MethodDungeonTools:CreateMenu();
	MethodDungeonTools:MakeTopBottomTextures(main_frame);
	MethodDungeonTools:MakeMapTexture(main_frame)
	MethodDungeonTools:MakeSidePanel(main_frame)
	MethodDungeonTools:MakePresetCreationFrame(main_frame)
	MethodDungeonTools:MakePresetImportFrame(main_frame)
	MethodDungeonTools:UpdateDungeonEnemies(main_frame)
	MethodDungeonTools:CreateDungeonSelectDropdown(main_frame)
	MethodDungeonTools:MakePullSelectionButtons(main_frame.sidePanel)
	MethodDungeonTools:MakeExportFrame(main_frame)
	MethodDungeonTools:MakeRenameFrame(main_frame)
	MethodDungeonTools:MakeDeleteConfirmationFrame(main_frame)
	MethodDungeonTools:MakeClearConfirmationFrame(main_frame)
	MethodDungeonTools:CreateTutorialButton(main_frame)
    MethodDungeonTools:POI_CreateFramePools()

    --devMode
    if db.devMode and MethodDungeonTools.CreateDevPanel then
        MethodDungeonTools:CreateDevPanel(MethodDungeonTools.main_frame)
    end


	--tooltip
    do
        tooltip = CreateFrame("Frame", "MethodDungeonToolsModelTooltip", UIParent, "TooltipBorderedFrameTemplate")
        tooltip:SetClampedToScreen(true)
        tooltip:SetFrameStrata("TOOLTIP")
        tooltip.mySizes ={x=265,y=110}
        tooltip:SetSize(tooltip.mySizes.x, tooltip.mySizes.y)
        tooltip:Hide()

        tooltip.Model = CreateFrame("PlayerModel", nil, tooltip)
        tooltip.Model:SetFrameLevel(1)
        tooltip.Model:SetSize(100,100)

        tooltip.Model.fac = 0
        if true then
            tooltip.Model:SetScript("OnUpdate",function (self,elapsed)
                self.fac = self.fac + 0.5
                if self.fac >= 360 then
                    self.fac = 0
                end
                self:SetFacing(PI*2 / 360 * self.fac)
				--print(tooltip.Model:GetModelFileID())
            end)

        else
            tooltip.Model:SetPortraitZoom(1)
            tooltip.Model:SetFacing(PI*2 / 360 * 2)
        end


		tooltip.Model:SetPoint("TOPLEFT", tooltip, "TOPLEFT",7,-7)

		tooltip.String = tooltip:CreateFontString("MethodDungeonToolsToolTipString");
		tooltip.String:SetFont("Fonts\\FRIZQT__.TTF", 10)
		tooltip.String:SetTextColor(1, 1, 1, 1);
		tooltip.String:SetJustifyH("LEFT")
		tooltip.String:SetJustifyV("CENTER")
		tooltip.String:SetWidth(tooltip:GetWidth())
		tooltip.String:SetHeight(80)
		tooltip.String:SetWidth(120)
		tooltip.String:SetText(" ");
		tooltip.String:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 110, -7)
		tooltip.String:Show();
	end

	--pullTooltip
	do
		MethodDungeonTools.pullTooltip = CreateFrame("Frame", "MethodDungeonToolsPullTooltip", UIParent, "TooltipBorderedFrameTemplate")
		MethodDungeonTools.pullTooltip:SetClampedToScreen(true)
		MethodDungeonTools.pullTooltip:SetFrameStrata("TOOLTIP")
        MethodDungeonTools.pullTooltip.myHeight = 160
		MethodDungeonTools.pullTooltip:SetSize(250, MethodDungeonTools.pullTooltip.myHeight)
		MethodDungeonTools.pullTooltip:Hide()

        MethodDungeonTools.pullTooltip.Model = CreateFrame("PlayerModel", nil, MethodDungeonTools.pullTooltip)
        MethodDungeonTools.pullTooltip.Model:SetFrameLevel(1)

        MethodDungeonTools.pullTooltip.Model.fac = 0
        if true then
            MethodDungeonTools.pullTooltip.Model:SetScript("OnUpdate",function (self,elapsed)
                self.fac = self.fac + 0.5
                if self.fac >= 360 then
                    self.fac = 0
                end
                self:SetFacing(PI*2 / 360 * self.fac)
            end)

        else
            MethodDungeonTools.pullTooltip.Model:SetPortraitZoom(1)
            MethodDungeonTools.pullTooltip.Model:SetFacing(PI*2 / 360 * 2)
        end

        MethodDungeonTools.pullTooltip.Model:SetSize(110,110)
        MethodDungeonTools.pullTooltip.Model:SetPoint("TOPLEFT", MethodDungeonTools.pullTooltip, "TOPLEFT",7,-7)

        MethodDungeonTools.pullTooltip.topString = MethodDungeonTools.pullTooltip:CreateFontString("MethodDungeonToolsToolTipString")
        MethodDungeonTools.pullTooltip.topString:SetFont("Fonts\\FRIZQT__.TTF", 10)
        MethodDungeonTools.pullTooltip.topString:SetTextColor(1, 1, 1, 1);
        MethodDungeonTools.pullTooltip.topString:SetJustifyH("LEFT")
        MethodDungeonTools.pullTooltip.topString:SetJustifyV("TOP")
        MethodDungeonTools.pullTooltip.topString:SetHeight(110)
        MethodDungeonTools.pullTooltip.topString:SetWidth(130)
        MethodDungeonTools.pullTooltip.topString:SetPoint("TOPLEFT", MethodDungeonTools.pullTooltip, "TOPLEFT", 110, -7)
        MethodDungeonTools.pullTooltip.topString:Hide()

        local heading = MethodDungeonTools.pullTooltip:CreateTexture(nil, "TOOLTIP")
        heading:SetHeight(8)
        heading:SetPoint("LEFT", 12, -30)
        heading:SetPoint("RIGHT", MethodDungeonTools.pullTooltip, "RIGHT", -12, -30)
        heading:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        heading:SetTexCoord(0.81, 0.94, 0.5, 1)
        heading:Show()

        MethodDungeonTools.pullTooltip.botString = MethodDungeonTools.pullTooltip:CreateFontString("MethodDungeonToolsToolTipString")
        local botString = MethodDungeonTools.pullTooltip.botString
        botString:SetFont("Fonts\\FRIZQT__.TTF", 10)
        botString:SetTextColor(1, 1, 1, 1);
        botString:SetJustifyH("TOP")
        botString:SetJustifyV("TOP")
        botString:SetHeight(23)
        botString:SetWidth(250)
        botString.defaultText = "Enemy Forces: %d\nTotal: %d/%d"
        botString:SetPoint("TOPLEFT", heading, "LEFT", -12, -7)
        botString:Hide()

	end

	--Blizzard Options
	MethodDungeonTools.blizzardOptionsMenuTable = {
		name = "Method Dungeon Tools",
		type = 'group',
		args = {
			enable = {
				type = 'toggle',
				name = "Enable Minimap Button",
				desc = "If the Minimap Button is enabled.",
				get = function() return not db.minimap.hide end,
				set = function(_, newValue)
					db.minimap.hide = not newValue
					if not db.minimap.hide then
						icon:Show("MethodDungeonTools")
					else
						icon:Hide("MethodDungeonTools")
					end
				end,
				order = 1,
				width = "full",
			},
            tooltipSelect ={
                type = 'select',
                name = "Choose NPC tooltip position",
                values = {
                    [1] = "Next to the NPC",
                    [2] = "In the bottom right corner",
                },
                get = function() return db.tooltipInCorner and 2 or 1 end,
                set = function(_,newValue)
                    if newValue == 1 then db.tooltipInCorner = false end
                    if newValue == 2 then db.tooltipInCorner = true end
                end,
                style = 'dropdown',
            },
            enemyForcesFormat = {
              type = "select",
              name = "Choose Enemy Forces Format",
              values = {
                [1] = "Forces only: 5/200",
                [2] = "Forces+%: 5/200 (2.5%)",
              },
              get = function() return db.enemyForcesFormat end,
              set = function(_,newValue) db.enemyForcesFormat = newValue end,
              style = "dropdown",
            },
		}
	}
	MethodDungeonTools:RegisterOptions()
	MethodDungeonTools:initToolbar(main_frame)
	main_frame:Hide()
end

