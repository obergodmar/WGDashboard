export const amneziaLegacyInterfaceFields = [
	"Jc", "Jmin", "Jmax",
	"S1", "S2", "S3", "S4",
	"H1", "H2", "H3", "H4",
	"I1", "I2", "I3", "I4", "I5",
	"J1", "J2", "J3", "Itime"
]

export const amneziaV3InterfaceFields = [
	"HeaderProtectionKey",
	"ContentPaddingAddition",
	"RekeyAfterTime",
	"RekeyTimeout",
	"RejectAfterTime",
	"KeepaliveTimeout",
	"MaxHandshakeAttempts",
	"RandomTrailers",
	"DisableCookies"
]

export const amneziaInterfaceFields = [
	...amneziaLegacyInterfaceFields,
	...amneziaV3InterfaceFields
]

export const amneziaBooleanFields = ["RandomTrailers", "DisableCookies"]

export const createDefaultAmneziaSettings = () => ({
	Jc: 5,
	Jmin: 49,
	Jmax: 998,
	S1: 17,
	S2: 110,
	S3: 1,
	S4: 2,
	H1: 0,
	H2: 0,
	H3: 0,
	H4: 0,
	I1: "0",
	I2: "0",
	I3: "0",
	I4: "0",
	I5: "0",
	J1: "",
	J2: "",
	J3: "",
	Itime: "",
	HeaderProtectionKey: "",
	ContentPaddingAddition: "",
	RekeyAfterTime: "",
	RekeyTimeout: "",
	RejectAfterTime: "",
	KeepaliveTimeout: "",
	MaxHandshakeAttempts: "",
	RandomTrailers: "",
	DisableCookies: ""
})

export const generateHeaderProtectionKey = () => {
	const key = new Uint8Array(32)
	window.crypto.getRandomValues(key)
	return btoa(String.fromCharCode(...key))
}
