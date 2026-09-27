<script>
import LocaleText from "@/components/text/localeText.vue";

export default {
	name: "persistentKeepAliveInput",
	components: {LocaleText},
	props: {
		data: Object,
		saving: Boolean
	}
}
</script>

<template>
<div>
	<label for="peer_keep_alive" class="form-label">
		<small class="text-muted">
			<LocaleText t="Persistent Keepalive"></LocaleText>
		</small>
	</label>
	<input type="text" class="form-control form-control-sm rounded-3 font-monospace"
	       placeholder="25 or 20-30 (AWG 3.x)"
	       :disabled="this.saving"
	       v-model="this.data.keepalive"
	       id="peer_keep_alive">
</div>
</template>

<style scoped>

</style>
