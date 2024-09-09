local isCameraActive = false
local currentCamMode = nil
local cam = nil
local frozenCamPos = nil

local CAMERA_MODES = {
	HEADCAM = "headcam",
	FROZEN = "frozen",
	STATIC = "static"
}

local offsets = {
	headcam = vector3(0.133, 0, 0.115),
	frozen = vector3(0.0, 0.0, 1.5),
	static = vector3(0.0, 0.0, 1.5)
}

RegisterCommand(
	"togglecam",
	function(source, args)
		if args[1] then
			local mode = args[1]:lower()
			if CAMERA_MODES[mode:upper()] then
				ToggleCamera(CAMERA_MODES[mode:upper()])
			else
				print("Invalid camera mode. Use: headcam, frozen, static")
			end
		else
			ToggleCamera(nil)
		end
	end,
	false
)

function ToggleCamera(mode)
	if isCameraActive then
		isCameraActive = false
		RenderScriptCams(false, false, 0, true, false)
		DestroyCam(cam, false)
		cam = nil
		currentCamMode = nil
		frozenCamPos = nil
	else
		isCameraActive = true
		cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

		currentCamMode = mode

		if currentCamMode == CAMERA_MODES.FROZEN or currentCamMode == CAMERA_MODES.STATIC then
			local playerPed = PlayerPedId()
			local boneIndex = GetPedBoneIndex(playerPed, 12844)
			local headPos = GetWorldPositionOfEntityBone(playerPed, boneIndex)
			frozenCamPos = vector3(headPos.x + offsets.frozen.x, headPos.y + offsets.frozen.y, headPos.z + offsets.frozen.z)
		end

		RenderScriptCams(true, false, 0, true, false)
		UpdateCamera()
	end
end

Citizen.CreateThread(
	function()
		while true do
			Citizen.Wait()
			if isCameraActive then
				UpdateCamera()
			end
		end
	end
)
function UpdateCamera()
	local playerPed = PlayerPedId()
	local playerHeading = GetEntityHeading(playerPed)

	if currentCamMode == CAMERA_MODES.HEADCAM then
		DisableCamCollisionForEntity(playerPed)
		local clip
		if IsPedRunning(playerPed) or IsPedSprinting(playerPed) then clip = 0.165 elseif IsPedInAnyVehicle(playerPed, false) then clip = 0.2 else clip = 0.155 end
		local boneIndex = GetPedBoneIndex(playerPed, 12844)
		local headPos = GetWorldPositionOfEntityBone(playerPed, boneIndex)
		local forwardX = -math.sin(math.rad(playerHeading))
		local forwardY = math.cos(math.rad(playerHeading))
		local offsetX = offsets.headcam.x * forwardX - offsets.headcam.y * forwardY
		local offsetY = offsets.headcam.x * forwardY + offsets.headcam.y * forwardX
		local offset = vector3(headPos.x + offsetX, headPos.y + offsetY, headPos.z + offsets.headcam.z)

		SetCamCoord(cam, offset)
		SetCamRot(cam, GetGameplayCamRot(2), 2)
		SetCamFov(cam, 90.0)
		SetCamNearClip(cam, clip)
	elseif currentCamMode == CAMERA_MODES.FROZEN then
		if frozenCamPos then
			SetCamCoord(cam, frozenCamPos)
			PointCamAtEntity(cam, PlayerPedId(), 0.0, 0.0, 0.5, true)
			SetCamFov(cam, 88.0)
			SetCamNearClip(cam, 0.01)
		end
	elseif currentCamMode == CAMERA_MODES.STATIC then
		if frozenCamPos then
			SetCamCoord(cam, frozenCamPos)
			local playerRot = GetGameplayCamRot(0)
			SetCamRot(cam, playerRot, 2)
			SetCamFov(cam, 88.0)
			SetCamNearClip(cam, 0.001)
		end
	end
end


AddEventHandler(
	"onResourceStop",
	function(resourceName)
		if resourceName == GetCurrentResourceName() then
			if cam then
				RenderScriptCams(false, false, 0, true, false)
				DestroyCam(cam, false)
			end
		end
	end
)

RegisterKeyMapping("togglecam frozen", "GoPro - Frozen Cam", "keyboard", "F6")
RegisterKeyMapping("togglecam static", "GoPro - Static Cam", "keyboard", "F7")
RegisterKeyMapping("togglecam headcam", "GoPro - Headcam", "keyboard", "F11")