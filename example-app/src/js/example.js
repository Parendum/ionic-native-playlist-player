import { NativePlaylistPlayer } from 'native-playlist-player';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    NativePlaylistPlayer.echo({ value: inputValue })
}
