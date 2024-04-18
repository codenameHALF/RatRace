extends Node3D

@onready var port = $CanvasLayer/SplashScreen/Port
@onready var splashScreen = $CanvasLayer/SplashScreen
@onready var isRat = $CanvasLayer/SplashScreen/IsRat
@onready var ip = $CanvasLayer/SplashScreen/IP


var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene
var playerInformation = {}
var connectedPlayers = []

signal change_color(color, id)

func _on_host_pressed():
	peer.create_server(int(port.text))
	multiplayer.multiplayer_peer = peer
	splashScreen.hide()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	rpc("send_client_information", [isRat.button_pressed])

func _on_join_pressed():
	peer.create_client(ip.text, int(port.text))
	multiplayer.multiplayer_peer = peer
	splashScreen.hide()
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_connected_to_server():
	rpc("send_client_information", [isRat.button_pressed])

@rpc("any_peer", "call_local")
func send_client_information(inClientInformation):
	if multiplayer.is_server():
		playerInformation[multiplayer.get_remote_sender_id()] = inClientInformation
		playerInformation[multiplayer.get_remote_sender_id()].append(len(playerInformation))
		connectedPlayers.append(multiplayer.get_remote_sender_id())
		rpc("sync_player_information", playerInformation, connectedPlayers)
		var player = player_scene.instantiate()
		player.name = str(multiplayer.get_remote_sender_id())
		call_deferred("add_child", player)
		await get_tree().create_timer(1).timeout
		rpc("sync_player_colors")

@rpc("authority", "call_remote")
func sync_player_information(inPlayerInformation, inConnectedPlayers):
	playerInformation = inPlayerInformation
	connectedPlayers = inConnectedPlayers

@rpc("authority", "call_local")
func sync_player_colors():
	for i in range(len(connectedPlayers)):
		change_color.emit(playerInformation[connectedPlayers[i]][1], connectedPlayers[i])

func _on_peer_connected(id = 1):
	pass

func _on_peer_disconnected(id):
	if multiplayer.is_server():
		playerInformation.erase(str(id))
		connectedPlayers.remove_at(connectedPlayers.find(id))
		print(connectedPlayers)
		rpc("sync_player_information", playerInformation)
		rpc("delete_player", id)

@rpc("any_peer", "call_local")
func delete_player(id):
	get_node(str(id)).queue_free()
