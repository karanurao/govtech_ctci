FROM wordpress:php8.1-apache
COPY wp-content /var/www/html/wp-content
RUN chown -R www-data:www-data /var/www/html/wp-content && \
    chmod -R 755 /var/www/html/wp-content    
RUN echo "upload_max_filesize = 50M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini
