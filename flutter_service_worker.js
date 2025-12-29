'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "41c79d223e703baccc813dfeb8cc6173",
"version.json": "d83cf4c14af8156a3745e63591ffe846",
"index.html": "e13e6ddbbe0f0d7f0306bfc6c57b6922",
"/": "e13e6ddbbe0f0d7f0306bfc6c57b6922",
"main.dart.js": "8ea788bcaf6390e0eb00a3656be6a6f8",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "aabb77299b92bf64b0de30ce629be1a1",
"icons/Icon-192.png": "aabb77299b92bf64b0de30ce629be1a1",
"icons/Icon-maskable-192.png": "aabb77299b92bf64b0de30ce629be1a1",
"icons/Icon-maskable-512.png": "aabb77299b92bf64b0de30ce629be1a1",
"icons/Icon-512.png": "aabb77299b92bf64b0de30ce629be1a1",
"manifest.json": "cb47c4dc25a7ae839dd8bfe7097c6b86",
".git/config": "22e676b05f045a3ab804be5556ed64a1",
".git/objects/95/4c9d53f7a999fe2898dbb1f9462198c2a7fdfa": "9abdf97f67e9b4802bb0cfd8e8f2fb0d",
".git/objects/92/e6d3aa3d9d8ec531dd4902a0aad539e03c703b": "52293ab683176b4ba2ced6289cba996d",
".git/objects/50/fd06f31d7193ee333e506d02cb012e975113fc": "8a192d7cba81e942dcd51f982efb5872",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/3b/def8bcb3ca181a90830446fceed434c81ecf4b": "f9bb6a599c0365880b3c110f8ad88731",
".git/objects/3b/ae30e3997e58e9481de6065c7c266bb43665e8": "0ba9af0106e1ff1bc4b37d00e287380b",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/6f/1108340fce8b9a28d255c2e61e2689edbd0df4": "9a8e6dab12ac35375a8aec72551e3c6c",
".git/objects/03/70b546f72c6f5ebe43be7f43ed98fd2edc3959": "352be05196d03abd04e9987803ddd148",
".git/objects/6a/40eb67bb9afa6c75e0c53fbf1e30de97daff15": "e77c00a76200b549a87a145240e55003",
".git/objects/69/b2023ef3b84225f16fdd15ba36b2b5fc3cee43": "6ccef18e05a49674444167a08de6e407",
".git/objects/69/db6cfafbf1fe5894d0fd8c0db7bcaf6f8f3aad": "01fd9782c8ffaffbc6b4b41086eedc1c",
".git/objects/56/06b4f5c9dc024b01577aea513510985aeb18f8": "5a0d373afcfabea857ecfb617f93a9a3",
".git/objects/51/e3cdf8cf99617d80285553901b8d2a592d7def": "b39c827596de0033027c235a4318aee5",
".git/objects/51/c2c7c3cbe096ffa3dbb1be74912a627dcfd5c5": "077aeec4372ba98b8ca0082115e35ab5",
".git/objects/51/3f20a8e10f42ac0f2dc68379828dc1eb278f5e": "48d5c6c17a90cba48f951132e2cb6151",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/3d/a9b3751ae81ea73349a3ab4ab87a35e1da33af": "21e0f6aad24956c98a962cbc1edb5322",
".git/objects/0b/77755a9d25fafb90e1c292ce6aac5ffb592fb0": "1ea61b6383b4cfe422c9f893f7c088a3",
".git/objects/0b/e8b6a56ace068769259aa7fab14c2a33b14749": "bae7c5e45add85bc76140fa2abaaaec6",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/94/df9d9a4098c3061434040351b55ae2b87586a9": "8ce6a94f1a3c66392c4d7f1adc6efccd",
".git/objects/34/72794aa28d918c00c3b220ac6c999fea2b4972": "4a938b7edc7823f2ac5d68d13c548bb4",
".git/objects/5a/f8444ee8b9898deacffadc326cf9b7f6104b67": "894b50ead929677d0b326a6008a4446a",
".git/objects/33/8bf79500d7045824ef71e8ce6fbc38a1470200": "9995d15d2507a16d3d7b385a500e4841",
".git/objects/02/d1bbe18d29ba7aa531f9101623216d561f29ab": "481053805fd451a9c69993116a182aaf",
".git/objects/a4/dd320d9d6fff4a166e10b15b6e1ee65677b74f": "89a7cd63ff9ccbf3e1f7efbc84860745",
".git/objects/b5/04559935d91e5662592afad79ce60a14c24073": "ab562db42a0556f89c9597e12ba3925b",
".git/objects/b5/33903ee0b228e605ad2968d09d23a8f95cad28": "213f0a07fc106af4ebe0ce377586803c",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/ac/5884f74543fe237c37e136b76245886d0523a2": "80c8c33d1efff6bab285bb00503bb6d8",
".git/objects/ad/0fc0de86275ad20068fd28475b1fef498b0cf7": "022bbae5fc8804a00528a37dfadd0bff",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/ad/2f60fa45750a34d1ea6800dd53f2bbe7010e2c": "155528426c50d1755e4355bd082ba267",
".git/objects/be/3b86797c472b377ca21e8d2802a8cde2a56b79": "211e46aff8ce9db2031da3bc5e347325",
".git/objects/da/5147d1b218dbe1f9ac38da18f7d254250ad487": "c0226754ceffde84687fb03aed53d443",
".git/objects/a2/1fd35e366fc9c3a71d83406dd6ef2f4f946864": "b9232e66561f44d75886093fa0c05cc8",
".git/objects/bd/dfca4d8e51006d1c6621c1b1ff62686a5248be": "db789075562363e1ace4cacf92276ff3",
".git/objects/d1/abb3675d7d927a501fe8d2d35199d5b583ee8b": "aab5f94d8b7b86bc962f0c41ca37c991",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f3/455cca463e01ec8cfc5956ea83fbc0e885272f": "0e1dd3ed98f416381c013077de033278",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/c0/4950be8bffd1decf2af1732454e71baeb8eedc": "4a80b2eb65a77373402c54158f1c6c36",
".git/objects/c9/48c22daa38e99dabfaac450c35663994c6c1ba": "9f47d5318f16d7efdd0bd8d68d8eef12",
".git/objects/c9/cbb280767b04193fa5fddbf23ccf712847098e": "f4838e39056a1feabb3bbac25b9f5cc5",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/e3/0928d41e6a46891b9a5801d409ee108b47685a": "526dea63dcf9061c4a84a601d3336227",
".git/objects/cf/2982daea08982d4802cfcf004e762810e2df35": "0fd21d883b8f46f9eab179a448dbf08a",
".git/objects/cf/a959ccfbe5afbb3b6e890354ea6f8436e77bdf": "db230ae2f6f89092f6f9d6f3b55d7f5c",
".git/objects/e4/ec2446e1adef2d616ca590a83cc6248b0e59ae": "9efc7b406683369dea4f8073dfba3f93",
".git/objects/c8/b8b709fed748caca3660b57c5855858525352b": "e2828aa98f10fb763f0dd178288c3371",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/c8/3c62e1a6db0065bb6c5d9d7db960588175fea2": "4b2f9a4bff47141ef58b2fd273266da8",
".git/objects/ed/0c7b746703a2d535ccb6475d871401db815a5b": "71c3d93ade5ec79e8ac6056b7984f2c9",
".git/objects/ec/eabeb10d6143f3d8c9ef563a85c1a8c2d9aab4": "05645f1deb513dd190d6bdc4391b3aca",
".git/objects/20/ccb852f704146abaec648cf93687054e25a21a": "348a39afea9a27388aeeea06bd76f230",
".git/objects/20/3ea776959cb94c2f3c63cda7aefeae678f6d41": "ecadc27e16a407a5e838e43e7fe26fb1",
".git/objects/18/1e32cd37f89aed697456603e3326cab210fa5b": "02bef946d63d6052e6bc91eaa64ae237",
".git/objects/27/b40f3681d6420baa07b1db20877b4d7c1d85ea": "03f993031a2ee1344bc65b807ff9ee81",
".git/objects/4b/5cc84064fcf2f5d9b3a81912a3fd957df57242": "63876187c4f9a6a9025130bf13984b89",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/16/c8dc60592c016093ec720824fa7887f332b535": "f5ca8ce34d10d84360b8cdadfd7d945a",
".git/objects/45/cd2cf88969dd69c94d28c49361a3ca38299e24": "bae8402c13434702b30126c1bacd17c2",
".git/objects/74/6c567ff4d304835d4eedab5c73dc60acabbd7f": "a40e649904521ed0c96cc503e00fbc1c",
".git/objects/17/141c222c2bd8cba3023e4bb1bc4844045b06f3": "cc3cb6a1aa82bd0d8ca7cbd5aab567d7",
".git/objects/8a/7568cf4f9a3b5ac68a3471c7a7cf5a1353adda": "d67b46f3ef117435d29edd774d8babeb",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/4d/c81726a9a72d5a09a23ae60e7bec2d3ae68984": "38e8b1f693ac5449801192001537687b",
".git/objects/75/52a9a4c41920211a3806c404f3e6ea73337908": "b1945a834403512e7bbebd20484d7c56",
".git/objects/72/2b29c80efe013c896df35a08ea4006a2dc3599": "b13d424ec088a3bad6f54168b60321f1",
".git/objects/44/622282d478a92cf8bb16839c3a7765188aa510": "9aaf3a8bd6400eda0e267ac26d20f3a8",
".git/objects/44/bbac0d97968506819ce9d71c95f365bc5bf8dc": "803dfd1af3d0e0caaa5481d72fc8dba2",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/9f/a04aa6d9b5295e0b2dafd76d8ab6c16b212169": "37675e0e2f70ccaf4fc01c55b7d9fd35",
".git/objects/6b/752dc835c8877b7653e61ad96782a99b746869": "76c276a92525f1818c069bc786e66fdc",
".git/objects/6b/cb5c21451e8eb01ee098d8ef6ff5d2cffccad6": "4510160ca9954ba816d875695c6258a3",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6e/548b126802424009950e7dfdeaf58ad0f4eb31": "8ba160b2ef92c7bbefbca89b1aa0e32d",
".git/objects/9a/5cc05857cfe41fd4ee7db2de7787d83928bb70": "a3af014bfd0e90eb3e8254c8d41c79e8",
".git/objects/5c/7a66fc91ea3193b5e7ccb512836fc48e966ef8": "9301c94509437b18e1bd4bbc97609e20",
".git/objects/5c/d402c38f82a8aff8bc09b36fd36cefc35e44a9": "1fb0998bd35cffe3e432eb5712c54775",
".git/objects/31/eb0a716f31d62967a837aa688f0ac26e3f8c4a": "c55ce58584c2bd78543430e318b479a1",
".git/objects/65/4ed10ca65a71de33f914100ad06eaff36bbf0a": "a7c196d18f7db03c2bd5f5a2d4c15345",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3a/3907a990674f2a473ded247fca3b92bdd5ef63": "98ad8d51f78f06670021430744e24228",
".git/objects/5e/7308fd6e1d857c479fc4300c7a6a9e8f4c0038": "2e2b5eaf0e879873359d1b3d279f878a",
".git/objects/37/af815a02b13fd799d97649939abd452ed02015": "f8ed77e4341651eab6893c320b5f79cf",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/6d/0121089baf23633b9eac98f47540a9026600fd": "bdf77a1c0a7f567aadbf13d1bfb9673c",
".git/objects/99/5918c5b1d7ff54b547fc43fbbc825ff428005d": "d814f809165e8b25bad8455fb5d100eb",
".git/objects/99/458b2ea6821799d0ef09a0fc2d5ffdb86b4907": "8e5cc50f95e31a31a61217f933b9545a",
".git/objects/52/bd1772931082a9e45a37d182f20a0be3d773d8": "1c9952e8794040b631da5f70a5aadd40",
".git/objects/97/d8874412cef7cce2a41e9c6388ad48a4832da1": "9b742e70d9380a04a3dc22999f7b8f85",
".git/objects/63/8b1862464d55ddb3558bfd33220589afbbbf14": "060756155225d37bb3e6e3a2c6bb7272",
".git/objects/0f/8043c56158bb4ae7634e171d5723d74972967a": "3d496ec55efbf5e9adbd18cec01ebd8b",
".git/objects/0f/332209a259ec21f90499c8ccc21a6b14c31a88": "e32c64322b6b8bfb48e175fe6f0e065e",
".git/objects/90/0fa2b85fc6f954ea48ffd674af5e378c265f84": "8081fd38c53c6621b5e72daa698a0f32",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/a7/137f7c89779ff08cbae0d1e1490e7f59558388": "d0cbc5e9efa5772afd0693f94018d8c0",
".git/objects/dc/40e0a87e8ae923db9538be999259c5918e31ed": "2e2007d375a91b4c6224669a24b57ccf",
".git/objects/b6/c52b1cb969e2d9ec35d7516cb5a750d591828f": "c1d98c468bbffbace3352755f3437429",
".git/objects/b6/0623f9b8e13fcb33117b828c66c8f012d1b742": "02f1fce9057bab614fa68b373de10376",
".git/objects/a9/76c4d0f09f779a1109a54c9db58e1093b23708": "0a850beabff6db5226f16c666b2b22e2",
".git/objects/d2/a61628c6d0377a231f38b015b0ee69b4d409e3": "03008064755019f9ae1e6e5829be11f3",
".git/objects/aa/e6d42df72dee3a9cfd30ec7bde13a6cd33fc1f": "f96bec9cf6a2bfd7e4bc36bc572b6dae",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b7/ababd46ab8d4a2bc02933add37d1b15234e5fd": "30d0af4651397f8118c12f3e98f948ec",
".git/objects/b7/ba2bd11b2dc7df0e23d5fdd1fced49198fcace": "3cfd610a2974983ea07f2fc2710f3f09",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/2c76abe11cc52523b82312112126c0ce2178ad": "d60a5c2e7d72c688ab584aec34c4cc41",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/ea/5adecc0b20b33a1bbdc8df73c88a0a3764bfbd": "f936d01e1cedb36ba9591957c6e08f45",
".git/objects/e1/f3c92c18f0a351e118df1514f09ed024d3bc5f": "b92aa2bf8d020565c30a7a289aa01217",
".git/objects/e6/297aeb545f01704bfecf65e1fbebb4cbe39c19": "379284e8cfdd76456139049ab381c45f",
".git/objects/e6/eb8f689cbc9febb5a913856382d297dae0d383": "466fce65fb82283da16cdd7c93059ff3",
".git/objects/f0/9cf857a269fd478ee35cc5fc7230f5d571e0a9": "a0b9eedfcd531db0357cdc2379c582e4",
".git/objects/f7/48da839200b5a86ebfe131e32f958514266974": "8a9b87129a941f00ffeec53983fe046c",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/e7/4259c5a6c4d9416f2ab9f24f815d4a7b9fa36d": "b73ce2d26516529bd96a1732b1c0f5e2",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/2c/01d2087a1c85827a86bc41c44ca260becd4c2c": "15633b0ee7657f83a4a0e58ba41c5da3",
".git/objects/2c/5240bfcd99b1b1bf62d2832953b405ab5820fc": "2a6267c996f7c8aebe2f99d259439c56",
".git/objects/2d/9da454518cd2bc49b259e75ca29500ea02b7c6": "d484dd4e33d4f94a18384b9804c4ee30",
".git/objects/1e/25ea2c9182d14729a36ff8288eee2cf27c48eb": "71c01fde6f0cde54702112e6368d5e81",
".git/objects/8d/0c5547ad0263aaf1f3ed634ea5e8088299fcad": "4021d06860f00891d2db53b5fe42cd78",
".git/objects/8c/c379bfcdcc7e1d4a3e2b1d8a8b89e6c99e3882": "ff9e7efbbcedc927763a4787e8b88990",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/76/e18192f16369018756adac35f1226347da4915": "d3bfc6ce4c9a80b6d2067f73fc74839e",
".git/objects/82/28d1afaab067c68ef64ea7dca7d2cabe693728": "61515317bb87cf9a1e1c63f35a7f836d",
".git/objects/49/d53741e04cbe16023f329a57906422ee84dd8d": "8eedc4e04fdcdae2a976f87bcfe6fa03",
".git/objects/8b/95472231c66e7fb39b60012ff6c37fa17d9d2b": "ebdb2ec8c23477b87c4a0ffb51c67bef",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "c50ca960551ef0a982bf64debeb93571",
".git/logs/refs/heads/main": "c50ca960551ef0a982bf64debeb93571",
".git/logs/refs/remotes/origin/gh-pages": "cbcfe554802608981ace1698fcb846e9",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/main": "c691e8a923c4d92fcd008fe3c975878f",
".git/refs/remotes/origin/gh-pages": "c691e8a923c4d92fcd008fe3c975878f",
".git/index": "1405eb3e565429aa253eb76455cd501b",
".git/COMMIT_EDITMSG": "a368ee69ca2f7d8583fa2539ccda568d",
"assets/NOTICES": "019fc88192cd0b88c3fd7a1477362525",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "d7eedf46c06ed307a5bb47701a6ad132",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_tesseract_ocr/images/test_16.jpg": "35314971c77f915dd1bf0b9579a84960",
"assets/packages/flutter_tesseract_ocr/images/test_11.jpg": "0d635defc90b9fa1df0ba9def0eeb9cb",
"assets/packages/flutter_tesseract_ocr/images/test_1.jpg": "0a2be1304ca3660cbd959ab65d45f98f",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "dc59e94bcaccd2360cd81327f20fb6f5",
"assets/fonts/MaterialIcons-Regular.otf": "9a917589fe10be4fb205b04aaf356df8",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
