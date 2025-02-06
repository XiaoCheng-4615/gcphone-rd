<template>
  <div class="notifications">
    <div
      v-for="(notification, id) in notifications"
      :key="id"
      class="notification"
      :class="notification.type"
    >
      {{ notification.message }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'notification',
  data () {
    return {
      notifications: []
    }
  },
  created () {
    this.$bus.$on('notification:show', this.showNotification)
  },
  beforeDestroy () {
    this.$bus.$off('notification:show', this.showNotification)
  },
  methods: {
    showNotification ({ message, type = 'info', timeout = 3000 }) {
      const id = Math.random().toString(36)
      this.notifications.push({ id, message, type })
      setTimeout(() => {
        this.notifications = this.notifications.filter(n => n.id !== id)
      }, timeout)
    }
  }
}
</script>

<style lang="scss" scoped>
.notifications {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 1000;
}

.notification {
  margin-bottom: 10px;
  padding: 10px 20px;
  border-radius: 4px;
  color: white;
  background-color: #44A4FC;
  
  &.success {
    background-color: #68CD86;
  }
  
  &.error {
    background-color: #E54D42;
  }
}
</style>