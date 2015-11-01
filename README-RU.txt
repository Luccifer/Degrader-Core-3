Основная концепция нового ядра Degradr.

1. Повсеместное использование Metal SDK для сокращения издержек на управления текстурами
2. Расспараллеливание расчетов на одном GPU
3. Изменение идеи слоя работы с представление данных.


Основные классы.


Контекст. DPContext.

Как и в предыдущей версии перед началом работы с процессингом нужно определить один или несколько контекстов в которых будет выполнятся весь пайплайн расчетов.
Контектс определяется созданием объекта типа DPContext. Например: 
    
    DPContext *context = [DPContext new]; // в основном больше ничего для создания контекста не нужно.

Важным отличием от предыдущей версии является возможность задать максимальный размер текстуры с которой работает приложение. 
В версии DegradrCore2 размер всегда опеределялся как максимальный размер с которым может работать GPU. 
В DegradrCore3 можно задать собственный максимальный размер, который не может быть больше максимального размера GPU:

    [DPContext setMaximumTextureSize: 1500]; // установить максимальный контекст с которым будет работать приложения во всех своих инстансах контекстов
    DPContext *context = [DPContext new];   // весь последующий импорт кртинок через провайдеры будет автоматически ресайзится до размера 1500 по большой стороне

Это можно использовать для управления размером каритинки для платных не платных - выставлять при старте приложения или смене оплаты. 
Тогда для бесплатных версий сильно улучшиться скорость обработки и объем занятой памяти.


Провайдеры текстур. DPImageProvider <DPTextureProvider>

Это концептуальное отличие от DegradrCore2. Теперь фильтры на прямую обрабатывают изображение опеределенного класса, 
а всегда работают с абстрактынм типом данных DPImageProvider. DPImageProvider обеспечивает связывание конкретного типа картинки с контекстом процессинга фильтра. 
Конкретные реализации провайдеров могут связывать фильтры с текстурами картинок UIImage, CVPixelBuffer, jpeg-file. 
DPImageProvider также может экспортировать текстуры в jpeg-file и через экстеншены в UIImage и NSData (jpeg в памяти). Например:

    [DPContext setMaximumTextureSize: 1500]; 
    DPContext *context = [DPContext new];  

    // создать провайдер текстуры, причем текстура сразу даунскейлистя до 1500 по большой стороне
    DPImageProvider  *provider = [DPImageFileProvider newWithImageFile:@"image.jpg" context:context];     
    NSError *error;
    // сохранить текстуру в jpeg-file с качестом 90% 
    [provider writeJpegToFile:@"new-image.jpg" quality:.9 error:&error];
    //
    if (error) NSLog(@"фигня какая-то с сохранением");

DPImageProvider реализует протокол id<DPTextureProvider>. 

Основные свойства:
 
 - imageOrientation - оригинальная ориентация текстуры, (writable)

Основные методы:

   - (instancetype) initWithTexture:(DPTextureRef)texture context:(DPContext *)aContext - конструктор
   
   - (void) transformOrientation:(UIImageOrientation)orientation - трансформировать в соответсвие заданной ориентации, учитывается исходная и нормализуется к UIImageOrientatioUp
     можно использовать перед сохранением результата.
   
   - (void) writeJpegToFile:(NSString*)filePath quality:(CGFloat)quality error:(NSError**)error - записать текстуру как jpeg с соответствующим касчеством


Основные провайдеры:

   1. DPPixelBufferProvider - кэшированное получение текстуры из фрейма камеры, imageOrientation всегда Left для основной камеры
   2. DPUIImageProvider - провайдер текстуры из UIImage, imageOrientation == свойству UIImage
   3. DPImageURLProvider - провайдер текстуры из URL, imageOrientation == UIImageOrientationUp - всегда нормализован 
   4. DPImageFileProvider - самый экономичный способ получения большой текстуры, imageOrientation - неопределен, по умолчанию Up, имеет смысл использовать с конструктором:
      + (instancetype) newWithImageFile:(NSString*)filePath context:(DPContext *)aContext maxSize:(CGFloat)maxSize orientation:(UIImageOrientation)orientation;
      подразумевается, что работая с файлами мы знаем исходную ориентацию картинки. 
      Особенности: maxSize - рекомендательный размер, выходной размер картинки будет приведен к размерности кратной 2 (из-за особенностей декомпрессии в jpeg-turbo)


Расширения:
  
  UIImage(DPImageProvider)
  //
  // создать картинку из провайдера
  //
  + (UIImage*) imageWithImageProvider:(DPImageProvider*)provider scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
  + (UIImage*) imageWithImageProvider:(DPImageProvider*)provider;


  NSData(DPImageProvider)
  //
  // сгенерить в памяти jpeg данные из провайдера для сохранения.
  // внутри jpeg-turbo, поэтому экономичное решение вместо использования UIImage
  //
  + (NSData*) jpegWithImageProvider:(DPImageProvider*)provider quality:(CGFloat)quality;


Фильтры. DPFilter.

АПИ фильтров также кардинально изменен. По сути придется работать только со свойствами: input, texture, transform. Дополнительно экспортируется context на чтение.
Свойство input - объект с протоколом id<DPTextureProvider>. Через это свойство фильтр можно связать с произвольным источником данных для обработки текстуры.
Свойство texture - хранит результат работы фильтра. Как правило используется для передачи в качестве параметра новому провайдеру текстур. 
После чего результат можно либо сохранить в объекты изображений или данных в память, в файл или передать как источник для следующего фильтра.
Свойство transform - представляет из себя буфер команд над геометрическими трансформациями изображения.

Например:

    //1. создать фильтр с новым контекстом
    DPAWBFilter *awb = [DPAWBFilter newWithContext:[DPContext new]];

    //2. задать источник 
    awb.input = [DPImageFileProvider newWithImageFile:@"image.jpg" context:awb.context]; 
    // или как уменьшнную
    // awb.input = [DPImageFileProvider newWithImageFile:@"image.jpg" context:awb.context maxSize:1000.0f]; 
    // или из кратинки
    // awb.input = [DPUImageProvider newWithImage: [UIImage imageNamed:@"image.jpg"] context:awb.context maxSize:1000.0f]; 
    // или из URL
    // awb.input = [DPImageURLProvider newWithImageURL:@"file:/Documents/image.jpg" context:awb.context maxSize:1000.0f]; 

    //3. получить результат
    DPImageProvider *result = [DPImageProvider newWithTexture:awb.texture context:awb.context]; 
    
    //4. нормализовать ориентацию картики к какой-то ориентации
    [result transformOrientation: UIImageOrientationUp]; // прямая

    //5. сохранить обработанную картинку в жипег
    [result writeJpegToFile:@"new-image.jpg" quality:.9 error:nil];

     
Трансформации. DPTransform (DPTransformEncoder)

Трансформации могут выполняться в заданном регионе с определенным resample-фактором. По умолчанию регион вся картинка с resample-фаткором==1. 
Регион по сути задает кроп изображения. 
Основное свойство DPTransform:  encoder - энкодер комманд трансвофрмации или трансляции координат. Энкодер обернут аналогичными командами в трасформере.

Пример использования в DPTransform. 

    //1. создаем буфер трасформаций
    DPTransform *transform = [DPTransofrm new];

    //2. устанавливаем регион в который отображаются трансформации
    transform.cropRegion = (DPCropRegion){
        0.1,0.1,  // отступы от краев top, right
        0.1,0.1,  // left, bottom
    }
    
    //3. траснформации, повернуть на 45º по часовой стрелке
    [transform rotate:[DPTransform degreesToRad:45.0f]];

    //4. повернуть еще раз вправо на 90º
    [transform rotateRight];

    //5. Симметрично отзеркалить относительно центра по горизонтали
    [transform flipHorizontal];

    //6. Увеличить картинку в два раза
    [transform scale: 2.0f];

    //7. Применить трансформации к фильтру
    awb.transform = [transform copy];

    //8. Серелизация трансофрмации в словарь
    [transfrom toDictionary]

    //9. Десерелизация
    [transform fromDictionary: [transform toDictionary]]
  
    //10. Серелизация трансформации в json
    NSString *json = [DPArchiver jsonFromCoding: transform]    


Представление результатов.
Live-view точно также как и в DegraderCore2 - через встроенный view. Но теперь принципиально по другому можно реализовать вывод результата на экран:
через DPLiveView и DPImageView. Оба класса представляют спецефические реализации класса DPView.
Интерфейс почти точно такой же как у DPFilter, поскольку основное свойство DPView: filter - инстанс кокнретного фильтра. 
Свойства DPView: input, filterTransform, context - являются алиасами тех же свойств проперти filter. 
Остутствует свойство texture, которое терминируется на экранчик телефона. Различия между DPImageView и DPLiveView только в способе организации обновления экрана.
DPImageView обновляет собержимое только при изменении свойств: input/transform. 
DPLiveView изменяется с частотой развертки и используется для терминирования результатов обработки фильтра в режиме реального времени. 

Основная идея DPView убрать лишнее чтение данных преобразования и копирование текстур в UIImageView через инстанс UIImage, который требует значительных ресурсов на вычисление и хранение в памяти.
Т.е. сразу биндимся с источником и прикладываем фильтры и трансформации. Бонусом, при трансформациях получаем наглядное изменение картинки в результате 
действия фильтра.


DPLiveView/DPImageView имеют свойство 

    UIDeviceOrientation    orientation;

     и метод

    - (void) setOrientation:(UIDeviceOrientation)orientation animate:(BOOL) animate;

    для управления viewPort-ом отображения результата. Учитывается imageOrintation провайдера текстуры, поэтому должно отображать корректную ориетацию исходной текстуры. 
    Трасформации через свойство filterTransform прикладываются на уровне слоя рендеренга фильтра подготовленой текстуры в независимости от imageOrientation. 
    imageOrientation влияет только на ориентацию слоя представления. 

    
