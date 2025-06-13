from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.validators import RegexValidator

class UserManager(BaseUserManager):
    def create_user(self, username, email = None, password = None, **extra_fields):
        if not username:
            raise ValueError ("El nombre de usuario es obligatorio")

        email = self.normalize_email(email)
        user = self.model(username = username, email = email, **extra_fields)
        user.set_password(password)
        user.save(using = self._db)
        return user
    
    def create_superuser(self, username, email = None, password = None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'ADMIN')

        if extra_fields.get('is_staff') is not True:
            raise ValueError("El superusuario debe tener is_staff = True")
        if extra_fields.get('is_superuser') is not True:
            raise ValueError("El superusuario debe tener is_superuser = True")

        return self.create_user(username, email, password, **extra_fields)

class User(AbstractUser):
    ROLE_CHOICES = (
        ('ADMIN', 'Administrador'),
        ('WORKER', 'Trabajador'),
    )

    email = models.EmailField(unique = True)
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    role = models.CharField(max_length = 10, choices = ROLE_CHOICES, default = "WORKER")
    telefono = models.CharField(
        max_length = 12,
        validators = [RegexValidator(r'^\d{9}$')],
        help_text = 'Formato: +34600606060 o 600606060'
    )

    objects = UserManager()

    def is_admin(self):
        return self.role == "ADMIN"
    
    def is_worker(self):
        return self.role == "WORKER"
    
class Cuadrilla(models.Model):
    nombre = models.CharField(max_length = 100)
    descripcion = models.TextField(blank = True, null = True)
    trabajadores = models.ManyToManyField('User', limit_choices_to = {'role': 'WORKER'})
    responsable = models.ForeignKey(
        'User', 
        on_delete = models.SET_NULL, 
        null = True, 
        blank = True, 
        related_name = 'cuadrillas_dirigidas', 
        limit_choices_to = {'role':'WORKER'}
        )
    
    def __str__(self):
        return self.nombre