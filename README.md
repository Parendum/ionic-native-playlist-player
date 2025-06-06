# native-playlist-player

Native Sound/Music playlist for iOS and Android

## Install

```bash
npm install native-playlist-player
npx cap sync
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`setPlaylist(...)`](#setplaylist)
* [`getPlaylist()`](#getplaylist)
* [`play()`](#play)
* [`pause()`](#pause)
* [`stop()`](#stop)
* [`isPlaying()`](#isplaying)
* [`addListener('playerStateUpdate', ...)`](#addlistenerplayerstateupdate-)
* [`removeAllListeners()`](#removealllisteners)
* [`checkPermissions()`](#checkpermissions)
* [`requestPermissions()`](#requestpermissions)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### echo(...)

```typescript
echo(options: { value: string; }) => Promise<{ value: string; }>
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ value: string; }</code> |

**Returns:** <code>Promise&lt;{ value: string; }&gt;</code>

--------------------


### setPlaylist(...)

```typescript
setPlaylist(options: { playlist: string[]; duration_seconds: number; language_code: string; }) => Promise<void>
```

| Param         | Type                                                                                  |
| ------------- | ------------------------------------------------------------------------------------- |
| **`options`** | <code>{ playlist: string[]; duration_seconds: number; language_code: string; }</code> |

--------------------


### getPlaylist()

```typescript
getPlaylist() => Promise<{ playlist: string[]; duration_seconds: number; }>
```

**Returns:** <code>Promise&lt;{ playlist: string[]; duration_seconds: number; }&gt;</code>

--------------------


### play()

```typescript
play() => Promise<void>
```

--------------------


### pause()

```typescript
pause() => Promise<void>
```

--------------------


### stop()

```typescript
stop() => Promise<void>
```

--------------------


### isPlaying()

```typescript
isPlaying() => Promise<IsPlayingResponse>
```

**Returns:** <code>Promise&lt;<a href="#isplayingresponse">IsPlayingResponse</a>&gt;</code>

--------------------


### addListener('playerStateUpdate', ...)

```typescript
addListener(eventName: 'playerStateUpdate', listenerFunc: (event: NativePlaylistPlayerStatus) => void) => Promise<PluginListenerHandle> & PluginListenerHandle
```

| Param              | Type                                                                                                  |
| ------------------ | ----------------------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'playerStateUpdate'</code>                                                                      |
| **`listenerFunc`** | <code>(event: <a href="#nativeplaylistplayerstatus">NativePlaylistPlayerStatus</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt; & <a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

--------------------


### checkPermissions()

```typescript
checkPermissions() => Promise<PermissionStatus>
```

**Returns:** <code>Promise&lt;any&gt;</code>

--------------------


### requestPermissions()

```typescript
requestPermissions() => Promise<PermissionStatus>
```

**Returns:** <code>Promise&lt;any&gt;</code>

--------------------


### Interfaces


#### IsPlayingResponse

| Prop            | Type                 |
| --------------- | -------------------- |
| **`isPlaying`** | <code>boolean</code> |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### NativePlaylistPlayerStatus

| Prop                    | Type                 |
| ----------------------- | -------------------- |
| **`isPlaying`**         | <code>boolean</code> |
| **`currentTrackIndex`** | <code>number</code>  |
| **`elapsedSeconds`**    | <code>number</code>  |
| **`durationSeconds`**   | <code>number</code>  |

</docgen-api>
