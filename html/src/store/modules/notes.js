import PhoneAPI from './../../PhoneAPI'
const LOCAL_NAME = 'gc_notes_channels'

let NotesAudio = null

const state = {
  channels: JSON.parse(localStorage[LOCAL_NAME] || null) || [],
  currentChannel: null,
  messagesChannel: []
}

const getters = {
  notesChannels: ({ channels }) => channels,
  notesCurrentChannel: ({ currentChannel }) => currentChannel,
  notesMessages: ({ messagesChannel }) => messagesChannel
}

const actions = {
  notesReset ({commit}) {
    commit('NOTES_SET_MESSAGES', { messages: [] })
    commit('NOTES_SET_CHANNEL', { channel: null })
    commit('NOTES_REMOVES_ALL_CHANNELS')
  },
  notesSetChannel ({ state, commit, dispatch }, { channel }) {
    if (state.currentChannel !== channel) {
      commit('NOTES_SET_MESSAGES', { messages: [] })
      commit('NOTES_SET_CHANNEL', { channel })
      dispatch('notesGetMessagesChannel', { channel })
    }
  },
  notesAddMessage ({ state, commit, getters }, { message }) {
    const channel = message.channel
    if (state.channels.find(e => e.channel === channel) !== undefined) {
      if (NotesAudio !== null) {
        NotesAudio.pause()
        NotesAudio = null
      }
      NotesAudio = new Audio('//sound/tchatNotification.ogg')
      NotesAudio.volume = getters.volume
      NotesAudio.play()
    }
    commit('NOTES_ADD_MESSAGES', { message })
  },
  notesAddChannel ({ commit }, { channel }) {
    commit('NOTES_ADD_CHANNELS', { channel })
  },
  notesRemoveChannel ({ commit }, { channel }) {
    commit('NOTES_REMOVES_CHANNELS', { channel })
  },
  notesGetMessagesChannel ({ commit }, { channel }) {
    PhoneAPI.notesGetMessagesChannel(channel)
  },
  notesSendMessage (state, { channel, message }) {
    PhoneAPI.notesSendMessage(channel, message)
  }
}

const mutations = {
  NOTES_SET_CHANNEL (state, { channel }) {
    state.currentChannel = channel
  },
  NOTES_ADD_CHANNELS (state, { channel }) {
    state.channels.push({
      channel
    })
    localStorage[LOCAL_NAME] = JSON.stringify(state.channels)
  },
  NOTES_REMOVES_CHANNELS (state, { channel }) {
    state.channels = state.channels.filter(c => {
      return c.channel !== channel
    })
    localStorage[LOCAL_NAME] = JSON.stringify(state.channels)
  },
  NOTES_REMOVES_ALL_CHANNELS (state) {
    state.channels = []
    localStorage[LOCAL_NAME] = JSON.stringify(state.channels)
  },
  NOTES_ADD_MESSAGES (state, { message }) {
    if (message.channel === state.currentChannel) {
      state.messagesChannel.push(message)
    }
  },
  NOTES_SET_MESSAGES (state, { messages }) {
    state.messagesChannel = messages
  }
}

export default {
  state,
  getters,
  actions,
  mutations
}

if (process.env.NODE_ENV !== 'production') {
  state.currentChannel = 'debug'
  state.messagesChannel = JSON.parse('[{"channel":"teste","message":"teste","id":6,"time":1528671680000},{"channel":"teste","message":"Hop","id":5,"time":1528671153000}]')
  for (let i = 0; i < 200; i++) {
    state.messagesChannel.push(Object.assign({}, state.messagesChannel[0], { id: 100 + i, message: 'mess ' + i }))
  }
  state.messagesChannel.push({
    message: 'Message sur plusieur ligne car il faut bien !!! Ok !',
    id: 5000,
    time: new Date().getTime()
  })
  state.messagesChannel.push({
    message: 'Message sur plusieur ligne car il faut bien !!! Ok !',
    id: 5000,
    time: new Date().getTime()
  })
  state.messagesChannel.push({
    message: 'Message sur plusieur ligne car il faut bien !!! Ok !',
    id: 5000,
    time: new Date(4567845).getTime()
  })
}
