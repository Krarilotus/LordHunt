# Lord Hunt

**Yazar**: Monsterfish
**Sürüm**: 1.0.3

Lordunu yapay zekâdan saklamanı engeller. Her bölüm ayarlardan tek tek kapatılabilir.

## Müttefik kalesinde saklanan lord

Normalde saldıran bir yapay zekâ yalnızca senin kendi iç kalene yönelir. Lordun bir müttefikin kalesinde oturuyorsa yapay zekâ boş kaleni yerle bir eder ama lorduna hiç yaklaşmaz.

Bu modülle, lordun kendi surlarının dışında ve saldıranların yürüyerek giremediği bir müttefikin surları içindeyken:

- **Kendi kalende hâlâ insanlar ve binalar varsa:** ordu bölünür. Varsayılan olarak tam kuşatma (kuşatma çadırları, mühendisler, merdivenler, hendek doldurma) lordunun bulunduğu kaleye gider, ordunun yarısı da kendi kalene tek başına saldırır. Hangi kalenin tam kuşatma alacağını ve ordu payını değiştirebilirsin.
- **Kendi kalen boşsa:** tüm ordu lordunun bulunduğu kaleye yönelir.
- **Saldırı zaten sürerken lordun oraya geçerse:** saldıranlar yalnızca ordularının büyük kısmı hâlâ ayaktaysa (varsayılan %80) hedef değiştirir.

Ayrılan birlikler ulaşabildikleri en yakın binaya, sonra bir sonrakine saldırır; ulaşabilecekleri bina kalmadığında surlara vururlar. Okçular, arbaletçiler ve sapancılar yanlarında yürür ve oklarını binalara harcamak yerine karşılaştıkları düşman birliklerine ateş ederler.

## Lord avı

Saldıranların lorduna açık bir yolu oluştuğu anda o kaleye saldıran ordunun yarısı doğrudan lorda yönelir. Açık yol yıkılmış bir sur veya kapı binası, merdiven, kuşatma kulesi, çökmüş tünel ya da lordunun açıkta durması olabilir. Ordunun kalanı kuşatmaya devam eder.

- **Kimler gider:** önce ana ordunun lorduna en yakın birlikleri, sonra diğer saldırı birlikleri. Kuşatma araçları, mühendisler, merdivenciler ve tünelciler kendi görevlerinde kalır.
- **Tüm avcılar ölürse:** ordunun geri kalanı lordun peşine düşer.
- **Yolu tekrar kapatırsan (suru onarırsan):** avcılar kuşatmaya geri döner.
- **Geri çekilme:** yapay zekâ geri çekilme kararını eskisiyle tamamen aynı şekilde verir.

## Bilmeniz gerekenler

- **Kimleri etkiler:** yalnızca yapay zekânın insan oyunculara yaptığı saldırıları. Yapay zekâ ile yapay zekâ savaşlarına dokunulmaz.
- **Kayıtlar:** kayıt dosyana hiçbir şey yazılmaz. Yüklendikten sonra birlikler normal başlar ve birkaç an sonra yapay zekânın bir sonraki kontrolünde görevlerini yeniden alır.
- **Diğer modlar:** başka bir mod yapay zekânın saldırı mantığını değiştirdiyse bu modül kapalı kalır ve bunu `ucp3.log` dosyasına yazar.
