MongoDB 踩坑记录（可能会持续更新）
=============================

### 数据校验

#### 打开校验功能

使用 Hibernate 的时候我们可以利用 `javax.validation` 包中提供的一系列 API 对传入数据库的数据进行校验。使用 MongoDB 时，需要显式的在配置当中打开，不然校验不会生效：

```java
@Configuration
public class DataSourceConfig {

    @Bean
    public ValidatingMongoEventListener validatingMongoEventListener() {
        return new ValidatingMongoEventListener(validator());
    }

    @Bean
    public LocalValidatorFactoryBean validator() {
        return new LocalValidatorFactoryBean();
    }
}
```

#### Collection 类型校验

对一个 Document 类型当中的 Collection property 做校验时，需要在 property 上显式加上 `@Valid`，不然不会进行校验。

```java
@Document
@Data
public class Library {

    // ...
    
    // 必须加上这个注解
    // 不然 Book 里面的校验全部都没有作用
    @Valid
    List<Book> books;
}
```

### 索引有关

#### 使用非 ObjectId 作为 Id

MongoDB 默认会使用生成的 ObjectId 作为主键 ID：

```java
@Data
@Document
public class Book {
    @Id
    private String id;
    // ...
}
```

如果想使用自定义的 ID，也可以将 `@Id` 加在自定义字段上：

```java
@Data
@Document
public class Book {
    @Id
    private String bookId;
    // ...
}
```

但注意，这时 `bookId` 一定要进行初始化操作，不然 MongoDB 仍然会生成一个 ObjectId 作为主键。

同时，主键 `@Id` 一定是唯一的，因此不需要再使用 `@Indexed`。

#### 联合索引

和 MySQL 类似，MongoDB 的联合索引（Compound Index）也是按照最左原则进行匹配的。例如下面一个索引：

```java
@Data
@Document
@CompoundIndexes({
        @CompoundIndex(name = "code_and_owner_idx", unique = true, def = "{'code': 1, 'ownerId': 1}")
})
public class Book {
    @Id
    private String bookId;
    
    @NotBlank
    private String code;
    
    @NotBlank
    private String ownerId;
}
```

使用 `code` 和 `ownerId` 进行查询会 hit 到索引，使用 `code` 查询会 hit 到索引，但使用 `ownerId` 进行查询则会进行 Document 扫描，当数据量大的时候性能会有非常大的下降。因此在建立联合索引的时候应该特别注意字段的顺序。


### 事务有关

MongoDB 3.X 并不支持多 Document 的事务。MongoDB 4.0 才开始支持多 Document 的事务。

当在 Spring 使用时，单纯的加入 `@Transactional` 是不行的，需要显式的在配置当中打开：

```java
@Configuration
public class DataSourceConfig {

    @Bean
    MongoTransactionManager transactionManager(MongoDbFactory dbFactory) {
        return new MongoTransactionManager(dbFactory);
    }
}
```

MongoDB 4.0 的事务支持并不支持单机（Standalone）部署，因此如果使用本地开发的单机 MongoDB，加上 `@Transactional` 进行操作，会直接导致崩溃（MongoDrive 3.8.2）。

同时 MongoDB 4.0 不支持在分片（Sharding）部署上使用，对分片的支持计划 4.2 才推出。考虑到大部分公司使用的还是 3.X 的版本，因此 MongoDB 现在的事务支持基本是不可用的。设计 Mongo 文档格式的时候，应考虑尽量减少多文档事务的操作，

#### 参考资料

* https://docs.mongodb.com/manual/core/index-compound/
* https://docs.mongodb.com/manual/core/write-operations-atomicity/
